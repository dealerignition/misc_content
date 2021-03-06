namespace :radiant do
  namespace :extensions do
    namespace :typed_pages do
      
      desc "Runs the migration of the Typed Pages extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          TypedPagesExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          TypedPagesExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Typed Pages to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from TypedPagesExtension"
        Dir[TypedPagesExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(TypedPagesExtension.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
