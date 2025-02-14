Agentic Tools Proposal

1. Problem Statement

As Capital One scales its multi-agentic AI systems, there is a growing need for a standardized framework to build and integrate tools into GenAI workflows. Current challenges include:

Fragmented Tool Development – Non-standard APIs causing inconsistencies.

Lack of Unified Registration – No centralized mechanism to register, access, and manage tools.

Scalability & Flexibility – Need for modular, plug-and-play tool architecture.

Governance & Security – Tools lack consistent validation, metadata, and security controls.

Interoperability – Tools should integrate natively with frameworks like LangChain, Haystack, and LlamaIndex.

Objective

The goal is to develop a unified, extensible framework under c1.genai.workflows.tools that:

Provides a structured way to create and integrate tools.

Supports both internal and external tools with clear distinctions.

Standardizes validation, logging, security, and entitlements.

Incorporates best practices from LangChain, OpenAI’s structured tools, and industry frameworks.

2. System Architecture

2.1 Internal vs. External Tools

To ensure clarity, the framework will explicitly support two categories of tools:

Internal Tools (c1.genai.workflows.tools)

Built within Capital One's GenAI Workflows framework.

Use Pydantic-based models for strict validation.

Fully governed under Capital One's security policies.

Directly callable from workflow functions.

External Tools (APITool)

Not hosted within c1.genai.workflows.tools, but must be adapted into a standard format.

Require adapter interfaces (e.g., LangChain’s tool wrappers).

Must follow metadata standards to be compatible.

Validated via the same `Pydantic` models to ensure seamless integration.

Supports both synchronous and asynchronous execution.

3. Tool Registration & Standardization

All tools (internal & external) follow OpenAI-style function metadata with structured validation and registration.

Example: Internal Tool Registration

from c1.genai.workflows.tools import register_tool
from pydantic import BaseModel, Field

class GetBalanceInput(BaseModel):
    customer_id: str = Field(..., description="Customer unique ID")

class GetBalanceOutput(BaseModel):
    balance: float = Field(..., description="Customer's account balance")

def get_balance(input_data: GetBalanceInput) -> GetBalanceOutput:
    return GetBalanceOutput(balance=1000.00)

register_tool(
    name="get_balance",
    func=get_balance,
    input_model=GetBalanceInput,
    output_model=GetBalanceOutput
)

Example: External Tool (APITool)

from c1.genai.workflows.tools import APITool
from pydantic import BaseModel, Field

class PaymentOptionsInput(BaseModel):
    customer_id: str = Field(..., description="Customer unique ID")
    account_id: str = Field(..., description="Account unique ID")

class PaymentOptionsOutput(BaseModel):
    payment_methods: list[str] = Field(..., description="Available payment methods")
    preferred_method: str = Field(..., description="Preferred payment option")

payment_options_tool = APITool(
    name="get_payment_options",
    endpoint="https://exchange.api.c1.com/payment-options",
    method="GET",
    input_model=PaymentOptionsInput,
    output_model=PaymentOptionsOutput,
    async_mode=True
)

workflows.tools.register(payment_options_tool)

4. Model Context Protocol (MCP) Integration

What is MCP?

The Model Context Protocol (MCP) is a standardized framework that enables AI workflows to dynamically interact with external tools and services.

Key Features of MCP

Standardized Tool Invocation – Defines a uniform way to execute tools and retrieve results.

Context-Aware Execution – Tools can store, recall, and use contextual data dynamically.

Schema-Based Discovery – MCP clients can query an MCP server to discover available tools and their schemas.

Secure Communication – Ensures structured, policy-compliant interactions.

Example: Discovering and Registering MCP Tools

from c1.genai.workflows.tools import MCPClient

mcp_client = MCPClient(mcp_server="mcp://capitalone.tools")
available_tools = mcp_client.discover_tools()

for tool in available_tools:
    workflows.tools.register(
        name=tool.name,
        func=mcp_client.call_tool,
        input_model=tool.input_schema,
        output_model=tool.output_schema
    )

5. Security & Governance

Scope & Access Control

Each tool must define:

PUBLIC – Visible to all.

PROTECTED – Capital One internal.

PRIVATE – Internal tools only.

class Scope(str, Enum):
    PUBLIC = "public"
    PROTECTED = "protected"
    PRIVATE = "private"

Data Security and Field Scoping

A tool in this framework is the primary interface for external interactions. Rather than enforcing strict field exposure at the data model level, the tool itself should be responsible for managing access control and dynamically retrieving necessary data using an internal context manager.

Context-Aware Tool Execution

Each tool will have a context manager that allows missing fields (due to scoping restrictions) to be dynamically retrieved when the tool is executed. This ensures that tools remain usable even when not all required arguments are explicitly provided at instantiation.

from langchain.tools import StructuredTool
from pydantic import BaseModel, Field
from typing import Optional, Dict

class Context:
    """
    Holds runtime information such as user entitlements and session metadata.
    """
    def __init__(self, data: Dict[str, str]):
        self.data = data
    
    def get(self, key: str, default=None):
        return self.data.get(key, default)

class Tool(BaseModel):
    context: Optional[Context] = None
    
    def run(self, **kwargs) -> Dict[str, str]:
        """
        Retrieves missing fields from context and executes the tool logic.
        """
        if self.context:
            for key, value in self.context.data.items():
                kwargs.setdefault(key, value)
        
        return self._execute(**kwargs)
    
    def _execute(self, **kwargs) -> Dict[str, str]:
        """
        The actual execution logic for the tool. 
        Should be overridden by subclasses.
        """
        raise NotImplementedError("Subclasses must implement _execute method")
    
    def to_langchain_tool(self):
        """
        Converts this tool into a LangChain StructuredTool while allowing for missing
        field resolution via context at runtime.
        """
        return StructuredTool.from_function(
            name="generic_tool",
            func=lambda **kwargs: self.run(**kwargs),
            description="Dynamically retrieves required fields at runtime",
        )

class AccountTool(Tool):
    display_account_number: Optional[str] = Field(None, description="Display Account")
    account_reference_id: Optional[str] = Field(None, description="Internal Reference")
    
    def _execute(self, **kwargs) -> Dict[str, str]:
        """
        Concrete execution logic for fetching account details.
        """
        return {
            "display_account_number": kwargs.get("display_account_number", self.display_account_number),
            "account_reference_id": kwargs.get("account_reference_id", self.account_reference_id)
        }

# Example usage
context = Context({"account_reference_id": "ABC123XYZ"})
tool_instance = AccountTool(display_account_number="****1234", context=context)
lc_tool = tool_instance.to_langchain_tool()
response = lc_tool.run()
print(response)  # {'display_account_number': '****1234', 'account_reference_id': 'ABC123XYZ'}

Key Takeaways

Dynamic Argument Resolution: Fields that are not explicitly provided are retrieved via context when the tool is executed.

LangChain Integration: The to_langchain_tool method ensures compatibility while preserving dynamic field resolution.

Encapsulation of Execution Logic: The _execute method enforces clear separation between execution and input handling.

This approach provides a flexible mechanism for managing data access while ensuring seamless integration with downstream frameworks.

6. Error Handling & Retry Logic

Tools must implement retry strategies for failures.

Errors should follow structured exception classes.

class ToolExecutionError(Exception):
    """Generic error class for tool execution failures."""
    pass

7. Entitlements & Compliance

Global Entitlements – Region-based restrictions.

Account-Level Entitlements – Determines specific user permissions.

def check_entitlement(user_id, action):
    """Ensure the user has permission before execution."""
    if not has_permission(user_id, action):
        raise ToolExecutionError("User lacks entitlement for this action")

8. Tool Compatibility with AI Frameworks

To ensure tools work seamlessly with LangChain, Haystack, and LlamaIndex, we standardize:

Tool discovery & registration via workflows.tools.register().

Metadata adherence to OpenAI’s structured output standard.

9. Testing & Deployment

All tools must pass validation tests before deployment.

Logging & Tracing must be standardized.

import logging
logger = logging.getLogger("tool_execution")
logger.info("Tool executed successfully.")

Conclusion & Next Steps

What This Proposal Accomplishes

Clear distinction between internal, Exchange-based, and MCP-backed tools.

APITool provides a simple way to integrate external services.

MCP tools are auto-discovered and registered dynamically.

Security, validation, and logging mechanisms are enforced.

Next Steps

Gather feedback on this design.

Prototype c1.genai.workflows.tools.

Integrate with LangChain & Haystack.

