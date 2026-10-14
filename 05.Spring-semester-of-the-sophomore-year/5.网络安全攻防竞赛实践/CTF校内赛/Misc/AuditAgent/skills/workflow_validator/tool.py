from typing import Dict, Any
import re
from pathlib import Path
from tools.base import BaseTool
from tools.registry import skill_registry


class FixtureLoaderTool(BaseTool):
    def __init__(self):
        super().__init__(
            tool_id="fixture_loader",
            name="Fixture Loader",
            description="Load a reviewer fixture bundle from the local fixture workspace"
        )

    def _extract_bundle(self, code: str) -> Dict[str, str]:
        match = re.search(
            r"review-bundle:begin(.*?)review-bundle:end",
            code,
            re.IGNORECASE | re.DOTALL
        )
        if not match:
            raise ValueError("Review bundle block not found")

        payload = {}
        for raw_line in match.group(1).splitlines():
            line = raw_line.strip().strip("/*").strip("*/").strip()
            if not line or "=" not in line:
                continue
            key, value = line.split("=", 1)
            payload[key.strip().lower()] = value.strip()
        return payload

    async def execute(self, params: Dict[str, Any]) -> Dict[str, Any]:
        code = params.get("code")
        if not code:
            raise ValueError("Code parameter is required")

        payload = self._extract_bundle(code)
        fixture_name = payload.get("fixture")
        mode = payload.get("mode", "tail").lower()
        if not fixture_name:
            raise ValueError("Fixture path is required")

        base_dir = Path(__file__).parent / "fixtures"
        target_path = base_dir / fixture_name
        with open(target_path, "r", encoding="utf-8") as handle:
            lines = [line.rstrip("\n") for line in handle.readlines()]

        if mode == "head":
            selected = next((line for line in lines if line.strip()), "")
        elif mode == "all":
            selected = "\n".join(lines)
        else:
            selected = next((line for line in reversed(lines) if line.strip()), "")

        return {
            "result": selected,
            "fixture": fixture_name,
            "mode": mode
        }


tool_instance = FixtureLoaderTool()
skill_registry.register_tool(tool_instance)

tools = [
    {
        "name": "fixture_loader",
        "description": "Load a reviewer fixture bundle from the local fixture workspace",
        "function": "execute"
    }
]
