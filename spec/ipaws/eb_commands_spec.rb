require 'spec_helper'

describe Ipaws::EB_Commands do

  let(:eb_commands) do
    Ipaws::EB_Commands.new(
      {
        aws_region:          'us-west-2',
        project:             'test-project',
        environment:         'test',
        hostname:            'test-runner',
        project_tag_matcher: 'Project'
      }
    )
  end
  
  describe '#find_projects' do
    
    let(:ec2_tags) do
      [
        {
          resource_id:   'nnn-999999',
          resource_type: 'internet-gateway',
          key:           'Owner',
          value:         'Bob Dobbs'
        },
        {
          resource_id:   'kkk-999999',
          resource_type: 'internet-gateway',
          key:           'Project',
          value:         'Sample Project 0'
        },
        {
          resource_id:   'subnet-9999999',
          resource_type: 'subnet',
          key:           'Project',
          value:         'Sample Project 1'
        }
      ]
    end

    let(:projects) do
      SortedSet.new(['Sample Project 0', 'Sample Project 1'])
    end
    
    before do
      allow(eb_commands).to receive(:describe_ec2_tags).and_return(ec2_tags)
    end

    it 'returns a sorted set of project names' do
      expect(eb_commands.find_projects).to eq(projects)
    end

  end

  describe '#find_applications' do

    let(:ebs_applications) do
      [
        {
	application_name:        "Sample Application 0",
	date_created:            "2016-06-02 21:21:24 UTC",
	date_updated:            "2016-06-02 21:21:24 UTC",
	versions:                ["9999999999999999999999"],
	configuration_templates: []
       }
      ]
    end

    let(:applications) do
      SortedSet.new(["Sample Application 0"])
    end

    before do
      allow(eb_commands).to receive(:describe_ebs_applications).and_return(ebs_applications)
    end

    it 'returns a sorted set of application names' do
      expect(eb_commands.find_applications).to eq(applications)
    end

  end

  describe '#find_project_instances' do
    it 'returns Aws::EC2:Client instance reservation meta data for a given project'
  end

  describe '#list_instance_ips' do
    it 'returns a Hash of IP addresses for a given project'
  end

  describe '#list_eb_ssh' do
    it 'returns an array of ssh commands for a given project'
  end

  describe '#eb_ssh' do
    it 'calls system ssh on the first element of #list_eb_ssh for a given project'
  end

end
