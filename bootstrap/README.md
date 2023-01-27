# Bootstrapping the Bootstrapper

Ensure execution mode is set to Local:

https://app.terraform.io/app/hashi_strawb_testing/workspaces/bootstrap/settings/general

Ensure we have local AWS Creds with:

```
doors local sandbox

# This is an alias, using a custom bash function wrapper around Doormat. Others would use...
# eval $(doormat aws export --account aws_lucy.davinhart_test)
```

Apply:

```
terraform apply
```

Now set execution mode to Remote:

https://app.terraform.io/app/hashi_strawb_testing/workspaces/bootstrap/settings/general


Also ensure the workspace has creds for TFC (this is trivial and left as an exercise for the reader)