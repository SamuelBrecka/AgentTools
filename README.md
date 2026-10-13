# AgentTools 🛠️⚡

A modular collection of agent skills, behavioral rules, Model Context Protocol (MCP) servers, and workflow utilities engineered for **Google Antigravity** and advanced AI coding assistants.

---

## 📖 Overview

**AgentTools** provides a disciplined operational framework for autonomous AI coding agents. It blends strict single-flow execution, empirical verification gates, lazy senior developer pragmatism ("Ponytail"), concise communication ("Caveman"), and secure terminal execution via MCP.

### Core Pillars

- **🛡️ Safe Execution**: Dedicated MCP server (`safe-command-mcp`) allowing autonomous read-only inspection, builds, and test runs without prompting for user confirmation, while blocking destructive operations.
- **🎯 Single-Flow Execution**: Eliminates chaotic parallel agent loops in favor of ordered, checklist-tracked (`task.md`), single-task-at-a-time execution.
- **🧘 Ponytail Philosophy**: "Lazy senior developer" engineering ladder—favoring YAGNI, standard libraries, native platform features, zero unnecessary abstractions, and minimal diffs.
- **⚡ Caveman Communication**: High-density, token-efficient, fluff-free responses that prioritize direct code diffs and concrete answers over filler.
- **🔬 Verification Before Completion**: Mandatory empirical proof (test outputs, exit codes, logs) before any task is marked complete.

---

## 📂 Repository Structure

```text
AgentTools/
├── agents/                      # Custom agent persona definitions and reference profiles
├── configs/
│   └── mcp.template.json        # Template configuration for Antigravity MCP registration
├── mcp/
│   └── safe-command-mcp/        # Model Context Protocol server for safe command execution
│       ├── package.json
│       └── server.js            # Node.js MCP server with command whitelisting/blacklisting
├── rules/
│   └── AGENTS.md                # System instructions, tool translation, and execution rules
├── skills/                      # Modular capability packs for Antigravity agents
│   ├── brainstorming/           # Requirement & intent exploration before implementation
│   ├── caveman/                 # High-density, terse communication mode
│   ├── executing-plans/         # Single-flow execution of written implementation plans
│   ├── finishing-a-development-branch/ # Structured options for merge, PR, or branch cleanup
│   ├── ponytail/                # Lazy senior dev mode (minimalism, YAGNI, standard library)
│   ├── receiving-code-review/   # Rigorous handling of review feedback
│   ├── requesting-code-review/  # Code review guidelines and pre-merge verification
│   ├── single-flow-task-execution/ # Phased task execution with role-based review prompts
│   ├── systematic-debugging/    # Multi-phase root-cause analysis and condition-based waiting
│   ├── test-driven-development/ # Red-Green-Refactor workflows & anti-pattern avoidance
│   ├── using-git-worktrees/     # Isolated workspace management via Git worktrees
│   ├── using-superpowers/       # Skill discovery and on-demand loading protocol
│   ├── verification-before-completion/ # Empirical evidence checks prior to claiming success
│   ├── writing-plans/           # Granular step-by-step implementation planning
│   └── writing-skills/          # Skill authoring guidelines, conventions, and verification
├── setup.ps1                    # Automated setup script for Windows / PowerShell
└── .gitignore
```

---

## 🚀 Quick Start

### Prerequisites

- **Windows PowerShell 5.1+** or **PowerShell 7+**
- **Node.js 18+** & **npm**
- **Google Antigravity CLI** (`agy`) or **Antigravity IDE**

### Automated Setup

Run the setup script from the root of the repository:

```powershell
.\setup.ps1
```

The script automatically:
1. Installs npm dependencies for all MCP servers in `mcp/` (such as `safe-command-mcp`).
2. Registers `safe-command-mcp` into your user Antigravity configuration (`~/.gemini/antigravity-cli/mcp.json`).
3. Prepares user-level skill directories under `~/.gemini/skills/`.

### Manual Configuration

If you prefer to configure Antigravity manually, update your `~/.gemini/antigravity-cli/mcp.json` using the template from `configs/mcp.template.json`:

```json
{
  "mcpServers": {
    "safe-commands": {
      "command": "node",
      "args": ["<PATH_TO_AGENT_TOOLS>/mcp/safe-command-mcp/server.js"]
    }
  }
}
```

---

## 🔌 Safe Command MCP (`safe-command-mcp`)

The built-in MCP server exposes `run_safe_command`, the preferred tool for non-interactive execution of harmless terminal tasks.

### Features

- **Pre-approved Whitelist**:
  - **Inspection**: `Get-ChildItem`, `dir`, `ls`, `Get-Content`, `cat`, `type`, `Select-Object`, `Select-String`, `Where-Object`, `Measure-Object`, `Test-Path`
  - **Git Read-Only**: `git status`, `git diff`, `git log`, `git branch`, `git show`, `git ls-files`, `git rev-parse`
  - **Build & Test**: `mvnw test`, `mvnw compile`, `npm test`, `npm run build`, `npm run lint`
  - **Container Status**: `docker ps`, `docker images`
- **Destructive Command Guard**:
  - Explicitly blocks destructive commands like `rm`, `del`, `Remove-Item`, `rmdir`, `git push --force`, `git reset --hard`, and `Format-Volume`.
  - Prompts the agent to fall back to the standard shell tool when user confirmation is legitimately required.
- **High-Capacity Output Buffer**: Allocates a 10 MB buffer for verbose test suites and build outputs.

---

## 🧠 Skills Catalog

Each skill in `skills/` is structured with frontmatter metadata and clear execution triggers:

| Skill | Description | When to Use |
| :--- | :--- | :--- |
| **`brainstorming`** | Intent exploration and specification before creative work | Before adding features, changing component behavior, or starting UI design |
| **`caveman`** | Ultra-terse, token-saving communication mode | When `/caveman`, "be brief", or "less tokens" is requested |
| **`executing-plans`** | Single-flow execution of structured implementation plans | When an approved implementation plan is ready to be executed |
| **`finishing-a-development-branch`** | Clean completion, merge, PR creation, or branch cleanup | When all tasks and tests pass and code is ready for integration |
| **`ponytail`** | Lazy senior developer ladder (YAGNI, stdlib, minimal diffs) | On all coding, refactoring, bug fixing, and dependency decisions |
| **`receiving-code-review`** | Objective, evidence-driven evaluation of review feedback | When receiving code review comments before applying suggested changes |
| **`requesting-code-review`** | Pre-merge review gates and self-inspection | Prior to merging, submitting PRs, or completing major milestones |
| **`single-flow-task-execution`** | Sequential task runner with spec and quality review gates | Complex, multi-task features needing strict implementation control |
| **`systematic-debugging`** | 4-phase root cause analysis and condition-based waiting | When facing failing tests, crashes, or unexplained system behavior |
| **`test-driven-development`** | Red-Green-Refactor discipline and test antipattern prevention | Before writing implementation code for any feature or bug fix |
| **`using-git-worktrees`** | Directory-isolated workspaces for feature branches | When starting isolated branch work without disturbing the working tree |
| **`using-superpowers`** | Protocol for skill discovery and dynamic file loading | At session initialization or when locating task-specific skills |
| **`verification-before-completion`** | Mandatory empirical proof before claiming task completion | Before declaring fixes or tasks done; evidence before assertions |
| **`writing-plans`** | Multi-phase plan generation with verifiable task boundaries | When given requirements for multi-step engineering tasks |
| **`writing-skills`** | Creation, documentation, and verification of new skills | When developing or upgrading skills for Antigravity |

---

## 📜 Agent Rules & Directives (`rules/AGENTS.md`)

The `rules/AGENTS.md` file defines the standard operating procedure for agents interacting with workspaces using AgentTools:

1. **Tool Translation**: Bridges legacy tool invocations into native Antigravity primitives (`view_file`, `replace_file_content`, `run_safe_command`, `task_boundary`).
2. **Single-Flow Discipline**: Agents work strictly on one checklist item at a time, recorded live in `<project-root>/docs/plans/task.md`.
3. **Ponytail Ladder**:
   1. *Does this need to be built at all? (YAGNI)*
   2. *Does it already exist in this codebase?*
   3. *Does the standard library already do this?*
   4. *Does a native platform feature cover it?*
   5. *Does an existing dependency solve it?*
   6. *Can this be one line?*
   7. *Only then: write the minimum necessary code.*
4. **Evidence-First Verification**: Never say "done" without executing tests and displaying actual command output.

---

## 🛠️ Development & Customization

### Creating a New Skill

1. Create a new directory under `skills/<skill-name>/`.
2. Add a `SKILL.md` file with standard YAML frontmatter:
   ```markdown
   ---
   name: <skill-name>
   description: Use when <specific trigger or condition>
   ---

   # Skill Title

   ## Overview
   ...
   ```
3. Consult [`skills/writing-skills/SKILL.md`](skills/writing-skills/SKILL.md) for detailed style guides, Graphviz workflow conventions, and verification steps.

### Extending the Safe Command MCP Server

To whitelist additional safe commands (e.g., Python `pytest`, Go `go test`, or Rust `cargo test`):
1. Open `mcp/safe-command-mcp/server.js`.
2. Add your regex pattern to `ALLOWED_PATTERNS`.
3. Restart or reload your Antigravity agent session.

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).
