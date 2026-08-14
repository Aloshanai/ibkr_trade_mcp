# Contributing to `ibkr_trade_mcp`

Thank you for your interest in contributing to `ibkr_trade_mcp`! This project provides a Model Context Protocol (MCP) server for Interactive Brokers (IBKR), enabling AI assistants like Claude Desktop, Cursor, and custom LLM agents to perform trading operations, portfolio management, order previews, and market data discovery.

This document outlines the workflow, development environment setup, coding guidelines, and pull request procedures for contributing to this repository.

---

## 📜 Table of Contents

- [Code of Conduct & Issue Reporting](#-code-of-conduct--issue-reporting)
- [Contribution Workflow](#-contribution-workflow)
- [Local Development Setup](#-local-development-setup)
- [Coding Style & Development Guidelines](#-coding-style--development-guidelines)
- [Testing & Verification](#-testing--verification)
- [Pull Request Checklist](#-pull-request-checklist)

---

## 🤝 Code of Conduct & Issue Reporting

We strive to maintain a welcoming, inclusive, and collaborative open-source community. All contributors are expected to conduct themselves professionally and respectfully.

### Reporting Bugs & Feature Requests
Before creating a new issue, please search existing [GitHub Issues](https://github.com/Aloshanai/ibkr_trade_mcp/issues) to avoid duplicate reports.

When filing a new bug report, please include:
- **Environment Details**: OS, Dart SDK version (`dart --version`), and IBKR Client Portal Gateway version.
- **Steps to Reproduce**: Clear, sequential steps to reproduce the issue.
- **Expected vs. Actual Behavior**: What you expected to happen vs. what actually occurred.
- **Logs**: Relevant log output from `stderr` (ensure sensitive credentials, account numbers, or session tokens are scrubbed).

---

## 🔄 Contribution Workflow

1. **Fork the Repository**: Create a personal fork of [`Aloshanai/ibkr_trade_mcp`](https://github.com/Aloshanai/ibkr_trade_mcp) on GitHub.
2. **Clone your Fork**:
   ```bash
   git clone https://github.com/<your-username>/ibkr_trade_mcp.git
   cd ibkr_trade_mcp
   ```
3. **Create a Feature Branch**:
   Use descriptive branch names prefixing `feat/` for new features or `fix/` for bug fixes:
   ```bash
   git checkout -b feat/add-new-mcp-tool
   # or
   git checkout -b fix/order-preview-validation
   ```
4. **Make Changes & Commit**:
   Keep commits focused and atomic with clear commit messages:
   ```bash
   git commit -m "feat(tools): add new portfolio risk metric tool"
   ```
5. **Push and Submit a Pull Request**:
   Push your branch to GitHub and create a Pull Request targeting the `main` branch. Reference any open issues resolved by your PR (e.g., `Closes #48`).

---

## 🛠️ Local Development Setup

### Prerequisites
- **Dart SDK**: Version `>=3.0.0 <4.0.0` installed ([Dart SDK Installation Guide](https://dart.dev/get-dart)).
- **IBKR Client Portal Gateway**: Downloaded and running locally (default: `https://localhost:5000`) with active 2FA browser authentication.
- **Git**: For version control.

### Installation & Running

1. **Fetch Dependencies**:
   ```bash
   dart pub get
   ```

2. **Run the MCP Server Locally**:
   Run the stdio MCP server directly:
   ```bash
   dart run bin/main.dart
   ```

3. **Docker Development (Optional)**:
   Build and test the Docker container locally:
   ```bash
   docker build -t ibkr_trade_mcp .
   docker run -i --rm -e IBKR_GATEWAY_HOST=host.docker.internal ibkr_trade_mcp
   ```

---

## 📐 Coding Style & Development Guidelines

### 1. Idiomatic Dart Style
- Follow official Dart formatting conventions (`dart format`).
- Adhere to static analysis rules configured in `analysis_options.yaml` (`package:lints/recommended.yaml`).

### 2. Standard Output (`stdout`) Integrity Rule
- **CRITICAL**: Model Context Protocol (MCP) communicates strictly via standard output (`stdout`) using JSON-RPC 2.0.
- **NEVER use `print()` or write directly to standard output** in server execution code. Doing so corrupts the stdio JSON-RPC stream and breaks MCP client communication.
- All logging, diagnostic outputs, and debug messages MUST be routed exclusively to standard error (`stderr`) via `McpLogger`.

### 3. Thin Adapter Architecture
- MCP tools defined in `lib/src/tools/mcp_tools.dart` should act as **thin adapters**.
- Core domain logic, Gateway HTTP communication, and REST models belong in the `ib_trade_core` package.
- Tools should focus on MCP parameter extraction, validation, delegating to `ib_trade_core`, and returning formatted JSON-RPC responses.

### 4. Input Validation & Error Handling
- Validate all incoming tool arguments (e.g., `accountId`, `conid`, `symbol`).
- Return structured MCP error responses using `buildToolErrorResponse(...)` rather than throwing raw unhandled exceptions.

---

## 🧪 Testing & Verification

Before committing or submitting a PR, ensure all static analysis checks and automated unit tests pass cleanly.

1. **Check Code Formatting**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```

2. **Run Static Analysis**:
   ```bash
   dart analyze
   ```
   *Ensure 0 issues/warnings are reported.*

3. **Run Unit Tests**:
   ```bash
   dart test
   ```
   *Ensure all tests pass.*

---

## Checklist for Pull Requests

Before submitting your PR, verify:
- [ ] Code formatted with `dart format .`.
- [ ] `dart analyze` passes with 0 issues.
- [ ] `dart test` passes cleanly.
- [ ] New functionality includes corresponding unit test coverage in `test/`.
- [ ] Relevant documentation updated (`README.md`, `configure.md`, or docstrings).
- [ ] PR description references related GitHub issues (e.g. `Closes #48`).
