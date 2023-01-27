# Bootstrap AWS Creds for other workspaces

Finds all workspaces with specified tags, creates the needed IAM roles in AWS, and then the needed env vars on the workspace.

Based on examples from
https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/tree/main/aws


When starting from scratch, use the code in the `bootstrap` directory to create the dynamic creds needed for the bootstrap workspace.

Once that's done, you can use the code in this directory.