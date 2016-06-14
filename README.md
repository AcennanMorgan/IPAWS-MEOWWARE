
# IPAWS

Do you use AWS ?

Do you need to SSH into those instances ?

Do you hate having to use a web browser to find the instances and ip addresses ?

Then you should use ipaws! IP AWS... ipAWS... whatever way you want to read/say it as. :)

ipaws is a devops tool for listing and ssh-ing into ec2 instances. ipaws is especially helpful in environments that utilize
dynamically created ec2 instances from Elastic Beanstalk.

ipaws features filtering by:

 * AWS Credential Profile
 * AWS Region
 * Project
 * environment with regex matching (prod, stage, dev, etc.)
 * blue-green active/inactive

ipaws also integrates closely with a wide variety of ssh options (ProxyCommand, custom identity files, etc.) allowing 
you to ssh with a single command into even the most secure environments! The pain of logging into a server without a 
public IP or one that is behind a jump box will be a thing of the past with ipaws!

## Pre-requisites 

ipaws makes a few assumptions about your environment. Certain features may or may not work if your AWS environment
 is not properly configured.

1. **Project Tag Name** - Every application needs to be tagged to a project; this tag helps ipaws to group different 
    environments as part of the same project; default tag name used is "Project" but the tag name can be changed via the 
    ```project_tag_matcher``` config option. For example, other companies may tag their applications by the 
    "Application" tag, ```project_tag_matcher: "Application"``` would make ipaws work with that. 
    [Tagging Reference](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html)
    
2. **Environment Name** - For blue/green environments, the blue and green environment must include a string that matches
    both environments. Eg. ```myapp-prod-a, myapp-prod-b``` ipaws will be able to match on ```myapp-prod```.
     
3. **inactive/active CNAME** - ipaws uses cname matching to determine which environment is live and which environment is 
    inactive. A string must be in either the active or inactive cname to indicate its state. You can use the 
    ```inactive_matcher``` or the ```active_matcher``` config option signify this. Only one option has to be defined, 
     the opposite will be inferred.

## Installing as a gem
TODO: We'll have this up on rubygems.com soon!

### Without Rubygems

```
gem install specific_install
gem specific_install https://github.com/Malwarebytes/ipaws.git master
```

* rake install (while in the projects root directory)


## Config file

Please refer to [ipaws.config.sample](ipaws.config.sample) for an example config file and a starting point. A config 
file is almost a requirement if you want to use ipaws conveniently.

## Usage

    ipaws help
    Commands:
      ipaws help [COMMAND]   # Describe available commands or one specific command
      ipaws list SUBCOMMAND  # list information
      ipaws print_ssh        # print out usable ssh information
      ipaws ssh              # ssh into an existing instance
      ipaws version          # print ipaws release version

    
    Options:
      -p, [--project=PROJECT]                # Project to find instances for
      -P, [--aws-profile=AWS_PROFILE]        # AWS profile
      -r, [--aws-region=AWS_REGION]          # AWS region
      -a, [--active=ACTIVE]                  # Search for active servers
      -i, [--inactive=INACTIVE]              # Search for inactive servers
      -e, [--environment=ENVIRONMENT]        # A description of which environment to use, eg. "dev" or "prod". Uses regex as a matcher. When using environment
      -x, [--proxy=PROXY]                    # Enable ssh ProxyCommand; No argument defaults to default_proxy_command in configuration; argument overrides proxy config
      -h, [--hostname=HOSTNAME]              # Show full hostname instead of inactive
      -n, [--instance=N]                     # Specific instance number to connect to
      -y, [--identity=IDENTITY]              # ssh identity file
      -c, [--config=CONFIG]                  # Config to read from (yaml format). All other options will be merged with a config file present.
      -k, [--config-profile=CONFIG_PROFILE]  # Which profile to use in the config.
    
    ipaws list help
    Commands:
      ipaws list applications     # List all applications in EB
      ipaws list config_profiles  # List all the config profiles within the ipaws config file
      ipaws list help [COMMAND]   # Describe subcommands or one specific subcommand
      ipaws list ips              # List all instance ips for said application
      ipaws list projects         # List all projects for existing ec2 instances using tags, slow process
    
    Options:
      -P, [--aws-profile=AWS_PROFILE]  # AWS profile
      -r, [--aws-region=AWS_REGION]    # AWS region


Supported Environment Variables (and which option they correlate to)
```
        AWS_DEFAULT_REGION =>   -r, [--aws-region=REGION]
        AWS_DEFAULT_PROFILE =>  -P, [--aws-profile=PROFILE]
        IPAWS_PROJECT =>        -p, [--project=PROJECT]
        IPAWS_CONFIG_PROFILE => -k, [--config-profile=CONFIG_PROFILE]  
        IPAWS_CONFIG =>         -c, [--config=CONFIG]
```

### Config Option Precedence

Most options have multiple locations to define the same config option. ipaws merges all options and resolves
conflicts by the following precedence rules:

1. command line option
2. active config profile(s)
3. environment variable
4. default config profile block
5. built-in application defaults

Config profiles can be stacked together by separating them with a ```,``` or ```.```. This is supported in all three
 areas the ```config_profile``` option can be defined: 
 
 * command line via the ```-k``` option
 * ```CONFIG_PROFILE``` environment variable
 * ```default: config_profile``` config file option 
  
When conflicts occur between different config profiles, the first config profile listed that has the option set takes
precedence over the other config options.
 
For example, using the example config file:

```
ipaws -k im_a_teapot,dexter_lab
```

The project will be set to "ImATeaPot".


## Examples
### print_ssh

* Instance Number
* Environment name
* IP
* ssh command

```
    ipaws print_ssh
    
    1)
    	im-a-teapot-dev-a - inactive
    	1.1.1.1
    	ssh ec2-user@1.1.1.1
    2)
    	im-a-teapot-dev-b
    	0.0.0.0
    	ssh ec2-user@0.0.0.0
    1)
    	im-a-teapot-prod-a
    	1.1.1.1
    	ssh ec2-user@2.2.2.2
    2)
    	im-a-teapot-prod-b - inactive
    	0.0.0.0
    	ssh ec2-user@3.3.3.3
```
### ssh

* Environment name
* What command is running
* Waits a second then executes ssh command
* If an instance number is not specified the first instance from the ```print_ssh``` list will be ssh'd into.


```
    ipaws ssh -k im_a_teapot.inactive.dev
    For environment: 	im-a-teapot-dev-a - inactive
    Running: 	ssh ec2-user@1.1.1.1
    Authenticated to 1.1.1.1 ([1.1.1.1]:22).
    Last login: Mon Jan 01 00:00:01 1979 from 9.9.9.9
     _____ _           _   _      ____                       _        _ _
    | ____| | __ _ ___| |_(_) ___| __ )  ___  __ _ _ __  ___| |_ __ _| | | __
    |  _| | |/ _` / __| __| |/ __|  _ \ / _ \/ _` | '_ \/ __| __/ _` | | |/ /
    | |___| | (_| \__ \ |_| | (__| |_) |  __/ (_| | | | \__ \ || (_| | |   <
    |_____|_|\__,_|___/\__|_|\___|____/ \___|\__,_|_| |_|___/\__\__,_|_|_|\_\
                                           Amazon Linux AMI
    
    This EC2 instance is managed by AWS Elastic Beanstalk. Changes made via SSH
    WILL BE LOST if the instance is replaced by auto-scaling. For more information
    on customizing your Elastic Beanstalk environment, see our documentation here:
    http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/customize-containers-ec2.html
```
SSH man page found http://linuxcommand.org/man_pages/ssh1.html
