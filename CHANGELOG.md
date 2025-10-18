# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Fix Option ([F])** - New interactive option to ask the LLM to review and fix issues with generated code
  - Sends the suggested code back to the LLM with a prompt to identify and correct potential issues
  - Returns a corrected version that continues in the interactive loop for further refinement
  
- **Alternate Option ([A])** - New interactive option to request alternative solutions
  - Provides different approaches to solve the same problem
  - Tracks previously suggested solutions to avoid duplicates
  - Can be used multiple times to explore various implementation strategies
  - Each alternate request includes all previous solutions in the prompt context
  
- **Redirect Option ([R])** - New interactive option to customize or query about generated code
  - Prompts user for custom input about what to do with the suggested code
  - Supports both code modifications (e.g., "add error handling", "add comments") and questions (e.g., "explain what this does")
  - Returns either modified code or text explanations based on the request
  - Provides maximum flexibility for iterative code refinement

### Changed
- Interactive code prompt now displays six options instead of three:
  - `[C]opy to clipboard (default)` - Copy the code to your clipboard
  - `[E]xecute` - Run the code immediately
  - `[F]ix` - Ask the LLM to review and fix any issues with the code
  - `[A]lternate` - Request a different solution from the LLM
  - `[R]edirect` - Ask the LLM to modify the code or answer questions about it
  - `[X] Exit` - Just display without action

- Code handling now uses an interactive loop allowing iterative refinement without starting new prompts
- Enhanced user experience with ability to explore multiple solutions and incrementally improve generated code

### Technical Details
- Updated `Show-CodeActionPrompt` function with new option validation (F, A, R)
- Implemented interactive loop in `Invoke-LLM` function with state tracking for alternate history
- All new options leverage existing `Send-ToLLM` function infrastructure
- Loop continues until user selects Execute, Copy, or Exit options

## [Earlier Versions]

For changes in earlier versions, please refer to the [releases page](https://github.com/DevPossible/PoshLLM/releases).
