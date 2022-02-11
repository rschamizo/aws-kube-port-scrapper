variable "Userlist" {
  type = list(string)
  default = []
}

variable "KeybaseUser" {
  type = string
  default = ""
}

variable "DynamoIndexAttribute" {
  type = string
  default = ""
}

variable "DynamoTable" {
  type = string
  default = ""
}

variable "ProjectName" {
  type = string
  default = ""
}

variable "BucketNamePrefix" {
  type = string
  default = ""
}

variable "EmailtoNotify" {
  type = string
  default = ""
}

variable "SnsTopic" {
  type = string
  default = ""
}

variable "EksName" {
  type = string
  default = ""
}

variable "DynamoCreation" {
  type = bool
  default = false
}

variable "BucketCreation" {
  type = bool
  default = false
}

variable "SnsCreation" {
  type = bool
  default = false
}