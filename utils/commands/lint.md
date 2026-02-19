# Lint

Run and report results:

```bash
python -m pyright
ruff check --select=E402 .
pylint --disable=all --enable=C0415 .
```

Fix by moving imports to top. Keep suppressions only for circular imports, optional dependencies, or TYPE_CHECKING.

## Pyright Config

If no `pyrightconfig.json` exists, create one with:

```json
{
  "pythonVersion": "3.13",
  "typeCheckingMode": "strict",
  "include": ["."],
  "exclude": ["venv", ".venv"],
  "reportMissingImports": true,
  "reportMissingTypeStubs": true,
  "reportUnknownMemberType": false,
  "reportUnknownVariableType": false,
  "reportUnknownArgumentType": false,
  "reportUnknownParameterType": false,
  "reportUnknownLambdaType": false,
  "reportMissingTypeArgument": false
}
```

Noise rules disabled: `reportUnknownMemberType/VariableType/ArgumentType/ParameterType/LambdaType`, `reportMissingTypeArgument`.
