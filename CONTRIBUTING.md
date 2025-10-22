# Contributing to Docker Base Images

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## 🎯 Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## 🚀 Getting Started

### Prerequisites

- Docker 20.10+
- Git
- Make (optional but recommended)
- Node.js 20+ (for testing Node.js examples)
- Python 3.12+ (for testing Python examples)

### Setting Up Development Environment

1. **Fork and clone the repository**

```bash
git clone https://github.com/your-username/docker-base-images.git
cd docker-base-images
```

2. **Build the base images**

```bash
make build-all
```

3. **Run the example application**

```bash
make run-example
```

4. **Verify everything works**

```bash
curl http://localhost:8080/health
```

## 📋 How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**Good bug reports include:**
- Clear, descriptive title
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details (OS, Docker version, etc.)
- Relevant logs or screenshots

**Example:**

```markdown
**Bug**: Node.js app crashes on shutdown

**Environment:**
- OS: Ubuntu 22.04
- Docker: 24.0.5
- Image: node-base:1.0.0

**Steps to reproduce:**
1. Start container: `docker run -p 8080:8080 demo-node:latest`
2. Send SIGTERM: `docker stop demo-node`
3. Check logs: `docker logs demo-node`

**Expected**: Graceful shutdown
**Actual**: Container crashes with error...

**Logs:**
```
[error logs here]
```
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- Clear, descriptive title
- Detailed description of the proposed functionality
- Why this enhancement would be useful
- Possible implementation approach
- Any potential drawbacks

### Pull Requests

1. **Create a feature branch**

```bash
git checkout -b feature/your-feature-name
```

2. **Make your changes**

Follow the coding standards outlined below.

3. **Test your changes**

```bash
# Build affected images
make build-all

# Run tests
make test

# Lint Dockerfiles
make lint

# Security scan
make security-scan
```

4. **Commit your changes**

Use clear, descriptive commit messages:

```bash
git commit -m "feat: add Python FastAPI example"
git commit -m "fix: correct health check in Node base image"
git commit -m "docs: update README with deployment instructions"
```

**Commit message format:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Formatting, missing semicolons, etc.
- `refactor:` Code restructuring
- `test:` Adding tests
- `chore:` Maintenance tasks

5. **Push to your fork**

```bash
git push origin feature/your-feature-name
```

6. **Open a Pull Request**

- Fill in the PR template
- Link related issues
- Describe what changed and why
- Include screenshots for UI changes
- Request review from maintainers

## 🏗️ Project Structure

```
docker-base-images/
├── docker/
│   ├── base/              # Base Dockerfiles
│   └── entrypoint.sh      # Shared entrypoint script
├── examples/              # Example applications
│   └── node-app/
├── monitoring/            # Monitoring stack
├── .github/
│   └── workflows/         # CI/CD pipelines
├── tests/                 # Test files
└── docs/                  # Additional documentation
```

## 📝 Coding Standards

### Dockerfile Best Practices

1. **Use specific base image tags**
```dockerfile
# Good
FROM debian:bookworm-slim

# Bad
FROM debian:latest
```

2. **Minimize layers**
```dockerfile
# Good
RUN apt-get update \
 && apt-get install -y package1 package2 \
 && rm -rf /var/lib/apt/lists/*

# Bad
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2
```

3. **Order instructions for better caching**
```dockerfile
# Dependencies (changes less frequently)
COPY package.json .
RUN npm install

# Application code (changes more frequently)
COPY . .
```

4. **Use .dockerignore**

Always create `.dockerignore` files to exclude unnecessary files.

5. **Run as non-root user**
```dockerfile
USER appuser
```

6. **Include health checks**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1
```

### JavaScript/Node.js Standards

1. **Use const/let, not var**
2. **Handle errors properly**
3. **Implement graceful shutdown**
4. **Add structured logging**
5. **Include health and metrics endpoints**

### Python Standards

1. **Follow PEP 8**
2. **Use type hints**
3. **Handle exceptions properly**
4. **Add docstrings**
5. **Use virtual environments**

## 🧪 Testing

### Adding Tests

Tests should be added for:
- New features
- Bug fixes
- Security enhancements

### Running Tests

```bash
# All tests
make test

# Specific test
npm test --prefix examples/node-app
```

## 🔒 Security

### Security Guidelines

1. **Never commit secrets**
   - Use environment variables
   - Add sensitive files to `.gitignore`

2. **Keep dependencies updated**
   - Regularly update base images
   - Pin dependency versions

3. **Run security scans**
```bash
make security-scan
```

4. **Follow least privilege principle**
   - Use non-root users
   - Minimize permissions

### Reporting Security Vulnerabilities

**DO NOT** open public issues for security vulnerabilities.

Instead, email security@example.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## 📚 Documentation

### Documentation Standards

- Keep README.md up to date
- Add inline comments for complex logic
- Document all configuration options
- Include usage examples
- Update CHANGELOG.md

### Writing Documentation

- Use clear, concise language
- Include code examples
- Add screenshots for UI changes
- Keep formatting consistent

## 🎨 Style Guidelines

### Markdown

- Use ATX-style headers (`#`)
- Use fenced code blocks with language hints
- Include blank lines between sections
- Use tables for structured data

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Include `set -e` for error handling
- Add comments for non-obvious code
- Use meaningful variable names

## 🔄 Release Process

1. Update version in relevant files
2. Update CHANGELOG.md
3. Create pull request
4. After merge, tag release
5. GitHub Actions will build and publish

## ❓ Questions?

- Check existing [issues](https://github.com/yourusername/docker-base-images/issues)
- Open a [discussion](https://github.com/yourusername/docker-base-images/discussions)
- Read the [documentation](README.md)

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing! 🎉

