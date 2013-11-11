# CapProvision

## Server Provisioning
Capistrano scripts have been developed to provision a bare bones server. The steps below are for provisining a Rackspace Ubuntu 13.10 server with a Nginx/Unicorn/RVM/Postgresql stack. A different VPS or OS version could be supported with minimal effort. 

### A note regarding script prompting...
The scripts will prompt for information as required. In almost all cases, the following will be prompted for at the beginning of each script execution:

* `Server Target` - One or more IP addresses or hostnames of the servers to target or connect to.
* `SSH Port` - The SSH port to connect to, 22 is the default.
* `SSH Key File` - One or more SSH private key files used to connect to the server. The default files provided should be adequate.

Any prompt can be silenced by exporting the appropriate variable before executing the script. For example, to turn off prompting of the 'SSH Port', the following variable could be set:

	export SSH_PORT=22

The script will now use that variable rather than prompting for the value. The name of the variable to set will be shown each time the user is prompted for something. Simply use the syntax provided to turn off prompting for other variables as desired.

### A note regarding deployment configuration...
The script execution may be configured in a number of ways. Configuration parameters may be found at:

```
config/capistrano/deploy.yml
```

The parameters are pretty straight-forward. Simply modify the values as necessary.


### Now onto provisioning...
To get started head over to [Rackspace Cloud](http://www.rackspace.com/cloud/) and spin up a new Ubuntu 13.10 instance. Record the following information:

	<password>
	<ip_address>

Once the server is accessible, the first step is to copy over the public SSH key which will be used throughout the provision and deployment process. 

	cap provision:push_ssh_key

Enter the <ip_address> and <password> when prompted. The defaults are sufficient for other prompts. 

Next, install the necessary software dependencies on the server with the following script:

	cap provision:install

Then, setup that software by executing:

	cap provision:setup

At some point you will be prompted for the Nginx HTTP and HTTPS ports, the defaults of `80` and `443` should be adequate.

Lastly, Capistrano needs to setup some items prior to executing the deployment. This can be accomplished with:

	cap deploy:setup

The server is now ready to be deployed to.

## Application Deployment
Capistrano is used to facilitate the application deployment. The prompting will work the same as outlined in the Server Provisioning section.

Deploy the application:

	cap deploy

Initialize the database:

	cap db:init

Refresh Unicorn:

	cap app:unicorn_refresh

Test out the application:

	http://<ip_address>

On going deployments will be performed in a similar manner, with one potential difference. The `cap db:init` command above will drop/create the database. This might not be desired in all cases. To simply migrate the database, leaving existing data in tact, use this command instead:

	cap db:migate
	
And if additional data seeding is required, use:
	
	cap db:seed