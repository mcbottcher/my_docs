---
paths:
  - ".github/workflows/*.yml"
  - ".github/actions/**"
---

# GitHub Actions version pinning

Always use a full commit hash for `uses:` action references, never a bare tag. Tags are mutable and can be moved to point at different code, making them a supply-chain security risk. A commit hash is immutable.

Add an inline comment with the human-readable version tag:

```yaml
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
```
