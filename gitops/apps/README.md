# Per-tool overrides (advanced)

For v1, each tool's Helm values are inlined directly in the matching
`gitops/root/templates/<tool>.yaml` Application for simplicity.

When a tool's config grows, move its values here as `gitops/apps/<tool>/values.yaml`
and switch the Application to an ArgoCD multi-source reference. Keeping that split
out of v1 avoids the extra multi-source wiring while you're still learning the loop.
