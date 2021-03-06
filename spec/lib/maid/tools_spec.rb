require 'spec_helper'

module Maid
  describe Tools do
    before :each do
      @home = File.expand_path('~')
      FileUtils.stub!(:mv)

      Maid.ancestors.should include(Tools)
      @maid = Maid.new
      @logger  = @maid.instance_eval { @logger }
    end

    describe '#move' do
      before :each do
        @from    = '~/Downloads/foo.zip'
        @to      = '~/Reference/'
        @options = @maid.file_options
      end

      it 'should move expanded paths, passing file_options' do
        FileUtils.should_receive(:mv).with("#{@home}/Downloads/foo.zip", "#{@home}/Reference", @options)
        @maid.move('~/Downloads/foo.zip', '~/Reference/')
      end

      it 'should log the move' do
        @logger.should_receive(:info)
        @maid.move(@from, @to)
      end

      it 'should not move if the target already exists' do
        File.stub!(:exist?).and_return(true)
        FileUtils.should_not_receive(:mv)
        @logger.should_receive(:warn)

        @maid.move(@from, @to)
      end
    end

    describe '#trash' do
      before :each do
        @trash_path = @maid.trash_path
        @path = '~/Downloads/foo.zip'
      end

      it 'should move the path to the trash' do
        @maid.should_receive(:move).with(@path, @trash_path)
        @maid.trash(@path)
      end

      it 'should use a safe path if the target exists' do
        # Without an offset, ISO8601 parses to local time, which is what we want here.
        Timecop.freeze(Time.parse('2011-05-22T16:53:52')) do
          File.stub!(:exist?).and_return(true)
          @maid.should_receive(:move).with(@path, "#{@trash_path}/foo.zip 2011-05-22-16-53-52")
          @maid.trash(@path)
        end
      end
    end

    describe '#dir' do
      it 'should delegate to Dir#[] with an expanded path' do
        Dir.should_receive(:[]).with("#@home/Downloads/*.zip")
        @maid.dir('~/Downloads/*.zip')
      end
    end

    describe '#find' do
      it 'should delegate to Find.find with an expanded path' do
        f = lambda { }
        Find.should_receive(:find).with("#@home/Downloads/foo.zip", &f)
        @maid.find('~/Downloads/foo.zip', &f)
      end
    end

    describe '#locate' do
      it 'should locate a file by name' do
        @maid.should_receive(:cmd).and_return("/a/foo.zip\n/b/foo.zip\n")
        @maid.locate('foo.zip').should == ['/a/foo.zip', '/b/foo.zip']
      end
    end

    describe '#downloaded_from' do
      it 'should determine the download site' do
        @maid.should_receive(:cmd).and_return(%Q{(\n    "http://www.site.com/foo.zip",\n"http://www.site.com/"\n)})
        @maid.downloaded_from('foo.zip').should == ['http://www.site.com/foo.zip', 'http://www.site.com/']
      end
    end

    describe '#duration_s' do
      it 'should determine audio length' do
        @maid.should_receive(:cmd).and_return('235.705')
        @maid.duration_s('foo.mp3').should == 235.705
      end
    end

    describe '#zipfile_contents' do
      it 'should inspect the contents of a .zip file' do
        @maid.should_receive(:cmd).and_return("foo/foo.exe\nfoo/README.txt\n")
        @maid.zipfile_contents('foo.zip').should == ['foo/foo.exe', 'foo/README.txt']
      end
    end

    describe '#disk_usage' do
      it 'should give the disk usage of a file' do
        @maid.should_receive(:cmd).and_return("136     foo.zip")
        @maid.disk_usage('foo.zip').should == 136
      end
    end

    describe '#last_accessed' do
      it 'should give the last accessed time of the file' do
        time = Time.now
        File.should_receive(:atime).with("#@home/foo.zip").and_return(time)
        @maid.last_accessed('~/foo.zip').should == time
      end
    end

    describe '#git_piston' do
      it 'should pull and push the given git repository, logging the action' do
        @maid.should_receive(:cmd).with(%Q{cd "#@home/code/projectname" && git pull && git push 2>&1})
        @logger.should_receive(:info)
        @maid.git_piston('~/code/projectname')
      end
    end
  end
end
