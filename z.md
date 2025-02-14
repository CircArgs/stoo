## Unified Tool Exception Handling  

To ensure consistency and reliability in tool execution, `c1.genai.workflows.tools` enforces a **structured exception handling system**. This system provides **standardized error classes**, **automatic error logging**, and **retry mechanisms** where applicable.

### **1. Standardized Exception Hierarchy**  

All exceptions raised during tool execution will inherit from a base exception class, ensuring a unified error-handling approach across different tool types.

```python
class ToolExecutionError(Exception):
    """Base exception class for all tool execution errors."""
    pass

class ToolValidationError(ToolExecutionError):
    """Raised when input validation fails."""
    pass

class ToolInvocationError(ToolExecutionError):
    """Raised when the underlying function or API call fails."""
    pass

class ToolTimeoutError(ToolExecutionError):
    """Raised when a tool execution exceeds the allowed time limit."""
    pass
```

### **2. Automatic Error Logging**  

The `Tool` class will log all exceptions, ensuring that failures are traceable and actionable.  

```python
import logging

logger = logging.getLogger("c1.genai.workflows.tools")

try:
    result = some_tool.invoke(customer_id="12345")
except ToolExecutionError as e:
    logger.error(f"Tool execution failed: {str(e)}")
    raise
```

### **3. Exception Handling During Execution**  

The `Tool` class wraps execution in a structured try-except block, ensuring that all exceptions are **caught, logged, and raised in a predictable manner**.

```python
def invoke(self, **kwargs):
    try:
        validated_input = self.input_model(**kwargs)
        return self.func(validated_input)
    except ValidationError as e:
        raise ToolValidationError(f"Input validation failed: {e}") from e
    except Exception as e:
        raise ToolInvocationError(f"Tool function failed: {e}") from e
```

### **4. Retry Mechanism for Transient Failures**  

For tools interacting with external services (such as `APITool` or `MCPClient`), transient failures (e.g., network issues) should trigger **automated retries**.

```python
import time

def retry_tool_execution(tool, max_retries=3, **kwargs):
    for attempt in range(max_retries):
        try:
            return tool.invoke(**kwargs)
        except ToolInvocationError as e:
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
            else:
                raise
```

### **5. Scoped Exception Handling for AI Workflows**  

When using tools in AI workflows (e.g., via LangChain), scoped exception handling ensures failures do not cascade unnecessarily.

```python
try:
    langchain_tool = some_tool.to_langchain()
    langchain_tool.invoke()
except ToolExecutionError as e:
    print(f"LangChain tool execution failed: {e}")
```

### **Key Takeaways**  

- **Standardized exception classes** ensure consistency across all tools.  
- **Automatic logging** captures execution failures for debugging and monitoring.  
- **Input validation errors** are raised early, preventing malformed data from propagating.  
- **Retry logic** helps mitigate transient failures in external tool calls.  
- **Scoped exception handling** ensures failures are contained within their execution context.  

This approach provides **robust error handling** while maintaining the flexibility needed for agentic workflows and external API integrations.
