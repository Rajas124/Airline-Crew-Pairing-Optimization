# Contributing to Airline Crew Pairing Optimization

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/Airline-Crew-Pairing-Optimization.git
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup

- Julia 1.9+
- Gurobi (with valid license)
- Dependencies: JuMP, Gurobi.jl

## How to Contribute

### Bug Reports
- Check existing issues first
- Include a minimal reproducible example
- Specify Julia version, OS, and Gurobi version

### Feature Requests
- Describe the use case and expected behavior
- Link to relevant research or academic papers if applicable
- Consider computational complexity implications

### Code Contributions
- Follow Julia style guidelines
- Add tests for new functionality
- Update documentation and README as needed
- Submit a pull request with a clear description

## Areas for Contribution

- **Algorithm Improvements**: Better pricing strategies, pruning techniques
- **Performance Optimization**: Faster constraint checking, sparse matrix operations
- **Feature Extensions**: Multi-base scheduling, aircraft routing integration
- **Documentation**: Examples, tutorials, paper references
- **Testing**: Additional test cases, edge cases, benchmarks
- **Visualization**: Result dashboards, algorithm animations

## Code Style

- Use descriptive variable names
- Add comments for complex logic
- Include docstrings for exported functions
- Follow Julia naming conventions (lowercase_with_underscores for functions/variables)

## Testing

Before submitting a PR, ensure:
- All existing tests pass
- New tests are included for changes
- Code is properly documented

## Questions?

Feel free to open an issue with the `question` label or start a discussion.

Thank you for contributing!
