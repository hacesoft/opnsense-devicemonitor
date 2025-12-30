# Contributing to OPNsense Device Monitor

First off, thank you for considering contributing to OPNsense Device Monitor! It's people like you that make this plugin better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

---

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

### Our Standards

**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behavior includes:**
- Trolling, insulting/derogatory comments, and personal attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**When reporting a bug, include:**
- **Clear title** and description
- **Steps to reproduce** the problem
- **Expected behavior** vs actual behavior
- **Screenshots** if applicable
- **Environment details**:
  - OPNsense version
  - Plugin version
  - Network setup (VLANs, etc.)
  - Browser (for GUI issues)

**Use this template:**

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - OPNsense Version: [e.g. 24.1]
 - Plugin Version: [e.g. 1.0.0]
 - Browser: [e.g. Chrome 120]

**Additional context**
Any other context about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues.

**When suggesting an enhancement, include:**
- **Clear title** and description
- **Use case** - why is this useful?
- **Proposed solution** if you have one
- **Alternatives considered**
- **Additional context** or screenshots

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:
- `good first issue` - Simple issues perfect for newcomers
- `help wanted` - Issues where we need community help

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request

---

## Development Setup

### Prerequisites

- OPNsense 24.x test environment
- Python 3.8+
- PHP 8.1+
- Git
- Text editor or IDE (VSCode, PyCharm recommended)

### Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/opnsense-devicemonitor.git
cd opnsense-devicemonitor

# Add upstream remote
git remote add upstream https://github.com/hacesoft/opnsense-devicemonitor.git
```

### Development Environment

```bash
# Install to OPNsense (test environment)
make dev-install

# This installs with debug logging enabled
```

### Running Tests

```bash
# Python unit tests
make test-python

# PHP unit tests (if available)
make test-php

# Integration tests
make test-integration

# All tests
make test
```

### Live Development

```bash
# Watch for file changes and auto-reload
make dev-watch

# View logs in real-time
make dev-logs

# Manual daemon restart after changes
make dev-restart
```

---

## Pull Request Process

### Before Submitting

1. **Update your fork**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Test your changes**:
   ```bash
   make test
   make lint
   ```

3. **Update documentation**:
   - README.md if adding features
   - CHANGELOG.md with your changes
   - Code comments for complex logic

4. **Follow commit conventions**:
   ```
   type(scope): subject

   body (optional)

   footer (optional)
   ```

   **Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

   **Examples**:
   ```bash
   feat(scanner): add support for IPv6 devices
   fix(gui): correct device count in dashboard
   docs(readme): update installation instructions
   ```

### Submitting the PR

1. **Push to your fork**:
   ```bash
   git push origin feature/amazing-feature
   ```

2. **Create Pull Request on GitHub**:
   - Use clear, descriptive title
   - Reference related issues (`Fixes #123`)
   - Describe what changed and why
   - Include screenshots for GUI changes

3. **PR Description Template**:
   ```markdown
   ## Description
   Brief description of changes

   ## Related Issue
   Fixes #123

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   - [ ] Tested on OPNsense 24.x
   - [ ] Unit tests pass
   - [ ] Manual testing completed

   ## Screenshots (if applicable)
   Attach screenshots here

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex code
   - [ ] Documentation updated
   - [ ] No new warnings generated
   - [ ] Tests added/updated
   - [ ] CHANGELOG.md updated
   ```

### Review Process

1. **Automated checks** run (CI/CD if configured)
2. **Maintainer review** - may request changes
3. **Address feedback** - push additional commits
4. **Approval** - maintainer approves changes
5. **Merge** - maintainer merges to main

---

## Coding Standards

### Python Code

**Style**: PEP 8 compliant

```python
# Good
def scan_network(interfaces: list) -> dict:
    """
    Scan network interfaces for devices.
    
    Args:
        interfaces: List of interface names
    
    Returns:
        dict: Detected devices
    """
    devices = {}
    for interface in interfaces:
        devices[interface] = scan_interface(interface)
    return devices

# Bad
def scanNetwork(ifs):
    devs={}
    for i in ifs:
        devs[i]=scanInterface(i)
    return devs
```

**Key Rules**:
- 4 spaces indentation
- Snake_case for functions and variables
- PascalCase for classes
- UPPER_CASE for constants
- Docstrings for all functions
- Type hints where applicable
- Max line length: 100 characters

**Linting**:
```bash
# Run linter
make lint-python

# Auto-format
make format-python
```

### PHP Code

**Style**: PSR-12 compliant

```php
<?php
// Good
class DevicesController extends ApiMutableModelControllerBase
{
    /**
     * Search devices with pagination
     * 
     * @return array Device list
     */
    public function searchAction(): array
    {
        $result = $this->searchBase(
            'devices',
            ['mac', 'ip', 'vendor'],
            'mac'
        );
        return $result;
    }
}

// Bad
class devicescontroller {
  function search() {
    return $this->searchBase('devices',['mac','ip','vendor'],'mac');
  }
}
```

**Key Rules**:
- 4 spaces indentation
- PascalCase for classes
- camelCase for methods
- Opening braces on same line
- Type declarations
- PHPDoc comments

**Linting**:
```bash
# Run PHP linter
make lint-php
```

### JavaScript/HTML (GUI)

```javascript
// Good
function refreshDeviceTable() {
    $('#device-grid').bootgrid('reload');
}

$(document).ready(function() {
    initializeDeviceTable();
});

// Bad
function RefreshDeviceTable(){$('#device-grid').bootgrid('reload');}
$(document).ready(function(){InitializeDeviceTable();});
```

---

## Testing

### Unit Tests

```python
# tests/test_scanner.py
import unittest
from devicemonitor import scanner

class TestScanner(unittest.TestCase):
    def test_parse_arp_line(self):
        line = "? (192.168.1.1) at aa:bb:cc:dd:ee:ff on em0"
        result = scanner.parse_arp_line(line)
        
        self.assertEqual(result['ip'], '192.168.1.1')
        self.assertEqual(result['mac'], 'aa:bb:cc:dd:ee:ff')
        self.assertEqual(result['interface'], 'em0')
```

### Integration Tests

```bash
# Test full scanning workflow
make test-scan

# Test database operations
make test-db

# Test email notifications
make test-email
```

### Manual Testing Checklist

Before submitting PR:

- [ ] Install plugin from source
- [ ] Daemon starts successfully
- [ ] Manual scan works
- [ ] Devices appear in GUI table
- [ ] Status (online/offline) accurate
- [ ] Vendor lookup works
- [ ] Email notification sends
- [ ] Settings save correctly
- [ ] OUI database download works
- [ ] No errors in system log

---

## Documentation

### Code Comments

```python
# Good - Explains WHY
# Use pfctl instead of tcpdump because it's 100x faster
# and doesn't require packet capture
active_ips = get_active_ips_from_pfctl()

# Bad - States WHAT (obvious from code)
# Get active IPs
active_ips = get_active_ips_from_pfctl()
```

### Docstrings

```python
def check_device_activity_pfctl() -> set:
    """
    Load active IP addresses from pfctl state table.
    
    This function parses pfctl -ss output to extract local IP addresses
    that have active network connections. It's significantly faster than
    ping-based detection and works with static DHCP reservations.
    
    Returns:
        set: Set of active IP addresses (strings)
        
    Example:
        >>> active_ips = check_device_activity_pfctl()
        >>> '192.168.1.100' in active_ips
        True
    """
    # Implementation...
```

### README Updates

When adding features, update:
- Feature list in README.md
- Configuration section if adding settings
- Screenshots if changing GUI
- Example usage if relevant

---

## Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **OPNsense Forum**: [Plugin discussion thread](https://forum.opnsense.org/)

### Getting Help

Stuck? Ask for help:
1. Check existing documentation
2. Search closed issues
3. Ask in GitHub Discussions
4. Ping maintainers (don't abuse this)

### Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project README

---

## License

By contributing, you agree that your contributions will be licensed under the BSD 2-Clause License.

---

## Questions?

Don't hesitate to ask! We're here to help.

- **Email**: dev@example.com
- **GitHub**: Open an issue with `question` label
- **Forum**: [OPNsense forum thread](https://forum.opnsense.org/)

---

**Thank you for contributing!** 🎉

Your efforts help make OPNsense Device Monitor better for everyone.
