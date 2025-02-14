# Agentic Tools Proposal

## 1. Problem Statement

As Capital One scales its multi-agentic AI systems, it requires a standardized and flexible framework to register, validate, and execute internal and external tools within GenAI workflows.

### Current Challenges

- Inconsistent tool APIs – No standard way to integrate AI tools.
- Lack of structured validation – No enforcement of strict schemas.
- Limited interoperability – Tools need to work with frameworks like LangChain, Haystack, and LlamaIndex.
- Security and governance concerns – External tool calls must be validated and logged.

### Goals of `c1.genai.workflows.tools`

1. Standardize tool creation and execution via a unified `Tool` class.
2. Enable interoperability with major AI tool frameworks.
3. Ensure compliance with validation, security, and logging policies.
4. Support context-aware execution with managed context merging.

## 2. Tool Definition (`Tool` Class)

At the core of `c1.genai.workflows.tools` is the `Tool` class, which abstracts the creation, validation, and execution of AI tools.

### Key Features

- Takes input and output Pydantic models.
- Accepts either a `func` (sync) or `coroutine` (async), but not both.
- Validates input before execution.
- Provides `.invoke()` and `.ainvoke()` for execution.
- Supports `.context()` for managed context merging.
- Supports scope-based parameter filtering.
- Can be transformed into tools for LangChain, Haystack, etc.

### Example: Defining a Tool

```python
from c1.genai.workflows.tools import Tool
from pydantic import BaseModel, Field
import contextlib

class GetBalanceInput(BaseModel):
    customer_id: str = Field(..., description="Customer unique ID", scope="protected")

class GetBalanceOutput(BaseModel):
    balance: float = Field(..., description="Customer's account balance", scope="public")

def get_balance(input_data: GetBalanceInput) -> GetBalanceOutput:
    return GetBalanceOutput(balance=1000.00)

get_balance_tool = Tool(
    name="get_balance",
    func=get_balance,
    input_model=GetBalanceInput,
    output_model=GetBalanceOutput
)

workflows.tools.register(get_balance_tool)
```

### Execution: Invoke and Ainvoke

The `Tool` class provides two execution methods:

- `.invoke()` – Calls the function synchronously.
- `.ainvoke()` – Calls the function asynchronously.

```python
# Synchronous execution
result = get_balance_tool.invoke(customer_id="12345")
print(result)

# Asynchronous execution
import asyncio
async def run():
    result = await get_balance_tool.ainvoke(customer_id="12345")
    print(result)

asyncio.run(run())
```

## 3. Context Management (`.context()`)

Using `contextlib`, the `Tool` class provides a context manager that merges contextual arguments with direct function inputs.

### Example: Using Context in a Workflow

```python
with get_balance_tool.context(customer_id="12345") as tool:
    result = tool.invoke()
    print(result)
```

## 4. External Tools (`APITool`)

For API-based tools, `APITool` encapsulates an external API as a callable tool.

### Example: Wrapping an API in `APITool`

```python
from c1.genai.workflows.tools import APITool

payment_options_tool = APITool(
    name="get_payment_options",
    endpoint="https://exchange.api.c1.com/payment-options",
    method="GET",
    input_model=PaymentOptionsInput,
    output_model=PaymentOptionsOutput,
    async_mode=True
)

workflows.tools.register(payment_options_tool)
```

## 5. Model Context Protocol (MCP) Integration

### What is MCP

The Model Context Protocol (MCP) is a standardized interface that allows AI workflows to:

- Discover available external tools dynamically.
- Fetch input and output schemas directly from an MCP server.
- Execute tools securely with context-aware arguments.

### How `c1.genai.workflows.tools` Uses MCP

- Queries MCP servers to discover tools.
- Auto-registers MCP tools, enforcing validation and security.
- Ensures all tools follow Capital One’s governance rules.

### Example: Discovering and Registering MCP Tools

```python
from c1.genai.workflows.tools import MCPClient

mcp_client = MCPClient(mcp_server="mcp://capitalone.tools")
available_tools = mcp_client.discover_tools()

for tool in available_tools:
    workflows.tools.register(tool)
```

## 6. Interoperability: Transforming Tools for AI Frameworks

The `Tool` class provides built-in conversion methods to transform tools into compatible formats for:

- LangChain (`.to_langchain()`)
- Haystack (`.to_haystack()`)
- LlamaIndex (`.to_llamaindex()`)

### Example: Converting a Tool for LangChain

```python
langchain_tool = get_balance_tool.to_langchain()
```

## 7. Security and Governance

### Scope-Based Security

Each tool will define access control policies:

- **PUBLIC** – Open to all workflows.
- **PROTECTED** – Internal Capital One use only.
- **PRIVATE** – Restricted to specific users or services.

```python
class Scope(str, Enum):
    PUBLIC = "public"
    PROTECTED = "protected"
    PRIVATE = "private"
```

**Scopes for Fields** – Fields in input and output models are **public by default** but can be explicitly marked as `protected` or `private`.  

**Tool Validation** – The `Tool` class ensures that only valid scopes are assigned to fields. Any field with an invalid scope assignment will be rejected at registration.

### Scoped Parameter Management

The `Tool` class provides methods for filtering parameters and outputs based on scope:

- `.scoped_parameters(scope: str)` – Returns only the parameters up to the given scope, where scopes are hierarchical (`public < protected < private`).
- `.parameters` – Returns only the public parameters.

### Example: Using Scoped Parameters

```python
# Get only parameters available at the 'protected' scope or lower
protected_params = get_balance_tool.scoped_parameters(scope="protected")

# Get only public parameters
public_params = get_balance_tool.parameters
```

The same applies to output models.

### Scoped LangChain Tool Creation

The `Tool` class can create a **scoped LangChain tool**. This ensures that only parameters **up to the given scope** are exposed in the LangChain tool, while internally it still calls `.invoke()` or `.ainvoke()`.

```python
protected_langchain_tool = get_balance_tool.to_langchain(scope="protected")
```

Internally, the scoped tool:

- Exposes only the **parameters within the specified scope**.
- Calls `.invoke()` or `.ainvoke()` under the hood.
- Allows the use of `.context()` to fill missing parameters when the tool is used dynamically, including by an LLM.

### Example: Using Context with a Scoped Tool

```python
# Define a protected-scoped LangChain tool
langchain_tool = get_balance_tool.to_langchain(scope="protected")

# When called in an AI workflow, it can use context to provide missing arguments
with get_balance_tool.context(customer_id="12345"):
    langchain_result = langchain_tool.invoke()
```

This ensures that tools remain **context-aware, secure, and compliant** while integrating seamlessly with external AI frameworks.

## Conclusion and Next Steps

### Key Takeaways

- Unified `Tool` class for both internal and external tools.
- Built-in validation, context management, and execution logic.
- Scope-based security enforcement at the field level.
- Scoped execution for AI frameworks like LangChain.
- Seamless integration with MCP for automatic tool discovery.

### Next Steps

1. Prototype `c1.genai.workflows.tools` implementation.
2. Integrate with LangChain and Haystack for real-world use.
3. Finalize governance policies for external API tools.

This proposal delivers a scalable, extensible, and industry-aligned solution for AI-driven workflows. Let me know if any refinements are needed.
