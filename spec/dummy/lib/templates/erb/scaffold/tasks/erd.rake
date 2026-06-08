namespace :update do
  desc "Run rails-erd to generate docs/erd.pdf (Requires rails-erd and graphviz to be installed)"
  task :erd do
    Bundler.with_original_env do
      `erd`
    end
  end
end
