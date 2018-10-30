# Scripts for Provisioning AWS Components from the Command Line

**Author:** Nicholas Hunt-Walker

The deployment script assumes you have some zipped file that you want to deploy via Elastic Beanstalk.

You'll need to create a `params.sh` from the given `params.example.sh` file for it to work.
**Do not ever commit this file to anything.** 
Just `cp params.example.sh params.sh` and fill the given environment variables with the appropriate values for your setup.