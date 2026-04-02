---
paths:
  - ".pre-commit-config.yaml"
---

# pre-commit hook version pinning

Always use a full commit hash for `rev:`, never a bare tag. Tags are mutable and can be moved to point at different code, making them a supply-chain security risk. A commit hash is immutable.

Add an inline comment with the human-readable version tag:

```yaml
rev: cef0300fd0fc4d2a87a85fa2093c6b283ea36f4b  # v5.0.0
```
