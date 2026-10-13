import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { exec } from "child_process";
import { promisify } from "util";
import path from "path";

const execAsync = promisify(exec);

// Predvolený pracovný adresár projektu
const DEFAULT_CWD = process.env.PROJECT_ROOT || process.cwd();

// Zoznam povolených regex vzorov (bezpečné read-only, build a test príkazy)
const ALLOWED_PATTERNS = [
  // Prieskum súborov a PowerShell čítanie (vrátane aliasov a pipingu)
  /^(Get-ChildItem|dir|ls)\b/i,
  /^(Get-Content|cat|type)\b/i,
  /^(Select-Object|Select-String|Where-Object|Measure-Object)\b/i,
  /^(Test-Path)\b/i,

  // Git bezpečné operácie (inspekcia stavu a histórie)
  /^git\s+(status|diff|log|branch|show|ls-files|rev-parse)/i,

  // Maven build a testy (vrátane powershell relatívnych ciest .\mvnw)
  /^\.?\\?(\.\/)?mvnw(\.cmd)?\s+(test|compile|clean\s+test)/i,

  // Node / npm operácie
  /^npm\s+(test|run\s+build|run\s+lint)/i,

  // Docker stavové príkazy
  /^docker\s+(ps|images)/i,
];

// Zakázané deštruktívne vzory, ktoré nesmú prejsť ani cez reťazenie
const FORBIDDEN_PATTERNS = [
  /\b(rm|del|Remove-Item|rmdir)\b/i,
  /\bgit\s+(push\s+--force|reset\s+--hard|clean\s+-fd)/i,
  /\bFormat-Volume\b/i,
];

const server = new Server(
  { name: "safe-command-runner", version: "1.1.0" },
  { capabilities: { tools: {} } },
);

// 1. Zoznam a popis dostupných nástrojov
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "run_safe_command",
      description:
        "PRIMARY and PREFERRED tool for running non-destructive terminal commands without requiring interactive user approval. Use this for repository exploration (Get-ChildItem, dir, ls), inspecting code (git diff, git log, git status, Get-Content), and running tests or builds (mvnw, npm test). Do NOT use the default shell tool when this tool can fulfill the task.",
      inputSchema: {
        type: "object",
        properties: {
          command: {
            type: "string",
            description: "The PowerShell or CLI command to execute.",
          },
          cwd: {
            type: "string",
            description:
              "Optional working directory path. Defaults to the repository root.",
          },
        },
        required: ["command"],
      },
    },
  ],
}));

// 2. Spracovanie a vyhodnotenie príkazu
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name !== "run_safe_command") {
    throw new Error(`Unknown tool: ${request.params.name}`);
  }

  const rawCmd = request.params.arguments?.command;
  if (!rawCmd || typeof rawCmd !== "string") {
    return {
      content: [{ type: "text", text: "Error: No command provided." }],
      isError: true,
    };
  }

  const trimmedCmd = rawCmd.trim();

  // Kontrola zakázaných deštruktívnych vzorov
  const hasForbidden = FORBIDDEN_PATTERNS.some((pattern) =>
    pattern.test(trimmedCmd),
  );
  if (hasForbidden) {
    return {
      content: [
        {
          type: "text",
          text: `BLOCKED: Command contains potentially destructive operations. Use the default interactive terminal tool to ask the user for confirmation.`,
        },
      ],
      isError: true,
    };
  }

  // Pre príkazy s pipelinou (|) skontrolujeme počiatočný príkaz
  const primarySegment = trimmedCmd.split("|")[0].trim();
  const isAllowed = ALLOWED_PATTERNS.some(
    (pattern) => pattern.test(trimmedCmd) || pattern.test(primarySegment),
  );

  if (!isAllowed) {
    return {
      content: [
        {
          type: "text",
          text: `BLOCKED: Command "${trimmedCmd}" is not in the safe execution whitelist. If required, invoke the standard shell tool to prompt user approval.`,
        },
      ],
      isError: true,
    };
  }

  const targetCwd = request.params.arguments?.cwd || DEFAULT_CWD;

  try {
    const { stdout, stderr } = await execAsync(trimmedCmd, {
      cwd: targetCwd,
      shell: "powershell.exe",
      maxBuffer: 1024 * 1024 * 10, // 10 MB buffer pre rozsiahle výpisy testov
    });

    const output = (
      stdout ||
      stderr ||
      "Execution succeeded with no output."
    ).trim();

    return {
      content: [{ type: "text", text: output }],
    };
  } catch (err) {
    return {
      content: [
        {
          type: "text",
          text: `Command execution failed:\n${err.message}\n${err.stderr || ""}`,
        },
      ],
      isError: true,
    };
  }
});

// Spustenie stdio transportu
const transport = new StdioServerTransport();
await server.connect(transport);
