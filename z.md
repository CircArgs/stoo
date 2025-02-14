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
