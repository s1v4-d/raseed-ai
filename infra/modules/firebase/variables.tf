variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "chat_function_name" {
  description = "Name of the chat function for API rewrites"
  type        = string
  default     = "chat-assistant"
}
