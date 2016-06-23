require 'set'
require 'json'
require 'aws-sdk'

module Ipaws
  class EB_Commands
    attr_accessor :aws_profile, :aws_region, :project, :proxy,
                  :show_cname, :active, :inactive, :active_matcher, :inactive_matcher, :project_tag_matcher,
                  :instance, :environment, :identity

    def initialize(params)
      @aws_profile      = params[:aws_profile]
      @aws_region       = params[:aws_region]

      Aws.config[:region] = aws_region

      @project             = params[:project]
      @identity            = " -i #{params[:identity]}" if params[:identity]
      @environment         = params[:environment]
      @proxy               = params[:proxy]
      @proxy               = params[:default_proxy_command] if self.proxy == 'proxy' || self.proxy == true
      @show_cname          = params[:hostname]
      @active              = params[:active]
      @inactive            = params[:inactive]
      @instance            = params[:instance]
      @inactive_matcher    = params[:inactive_matcher]
      @active_matcher      = params[:active_matcher]
      @project_tag_matcher = params[:project_tag_matcher]

      if aws_profile
        credentials = Aws::SharedCredentials.new(profile_name: aws_profile)
      else
        credentials = Aws::SharedCredentials.new
      end

      raise 'Cannot load credentials' unless credentials.loadable?
      Aws.config[:credentials] = credentials
    end

    def find_projects
      SortedSet.new.tap do |projects|
        describe_ec2_tags.each do |tag|
          if tag[:key] == project_tag_matcher
            projects << tag[:value]
          end
        end
      end
    end

    def find_applications
      SortedSet.new(ebs_application_names)
    end

    def find_project_instances
      options = Hash.new.tap do |hash|
        if project
          hash[:filters] = [{ name: "tag:#{project_tag_matcher}", values: [project] }]
        end
      end
      
      Aws::EC2::Client.new.describe_instances(options)[:reservations]
    end

    def list_instances_ips
      data    = find_project_instances
      eb_data = ebs_environments

      cname_hash = {}
      eb_data.each do |environment|
        cname_hash[environment[:environment_name]] = environment[:cname]
      end

      # FIXME (cmhobbs) extract all this nested logic into useful methods and exceptions
      ip_hash = {}
      data.each do |reservation|
        reservation[:instances].each do |instance|
          address = instance[:private_ip_address]
          tag = instance[:tags].select {|t| t[:key] == 'Name'}.first
          env_name = tag[:value]
          cname = cname_hash[env_name]
          if active && !inactive && cname
            # skip inactives
            if inactive_matcher
              next if cname.include?(inactive_matcher)
            elsif active_matcher
              next if !cname.include?(active_matcher)
            else
              raise "'inactive_matcher' or 'active_matcher' must be set! Cannot determine active/inactive state without"
            end
          elsif inactive && !active && cname
            # skip actives
            if active_matcher
              next if cname.include?(active_matcher)
            elsif inactive_matcher
              next if !cname.include?(inactive_matcher)
            else
              raise "'inactive_matcher' or 'active_matcher' must be set! Cannot determine active/inactive state without"
            end
          end
          if environment
            next unless env_name =~ Regexp.new(environment)
          end
          if show_cname
            env_desc = cname.nil? ? '' : ' - '+cname
          elsif cname.nil?
            env_desc = ''
          else
            env_desc = cname.include?('inactive') ? ' - inactive' : ''
          end
          ip_hash[ address ] = env_name + env_desc
        end
      end
      ip_hash
    end

    def list_eb_ssh
      ip_hash = list_instances_ips

      number=0
      output = []

      # FIXME (cmhobbs) clean this up
      ip_hash.sort {|a,b| a[1]<=>b[1]}.each do |k,v|
        if k
          number+=1
          ssh_copy_paste = "ssh ec2-user@#{k}"
          ssh_copy_paste += " #{identity}" if identity
          if proxy
            proxycommand ||= "-o \"ProxyCommand ssh #{proxy} -W %h:%p\""
            ssh_copy_paste += " #{proxycommand}"
          end
          if instance.nil?
            output << ["#{number})"]
            output[-1] << "\t#{v}"
            output[-1] << "\t#{k}"
            output[-1] << "\t#{ssh_copy_paste}"
          elsif instance == number
            output << ["#{number})"]
            output[-1] << "\t#{v}"
            output[-1] << "\t#{k}"
            output[-1] << "\t#{ssh_copy_paste}"
          end
        end
      end
      output
    end

    def eb_ssh
      instances = list_eb_ssh
      instance ||= 0
      output = instances[instance]
      puts "For environment: #{output[1]}"
      puts "Running: #{output[-1]}"
      sleep 1
      exec(output[-1])
    end

    private

    def describe_ec2_tags
      Aws::EC2::Client.new.describe_tags[:tags]
    end

    def ebs_application_names
      describe_ebs_applications.map { |record| record[:application_name] }
    end
    
    def describe_ebs_applications
      Aws::ElasticBeanstalk::Client.new.describe_applications[:applications]
    end

    def describe_ec2_instances(options)
      Aws::EC2::Client.new.describe_instances(options)
    end
    
    def ebs_environments
      Aws::ElasticBeanstalk::Client.new.describe_environments[:environments]
    end
    
  end
end
