gem "annotate"
# gem "cssbundling-rails"
gem "inline_svg"
gem "name_of_person"
# gem "strong_migrations" # Uncomment if you want to use strong_migrations
gem "bootstrap", "~> 5.3.3"
gem "dartsass-rails"
gem "openssl", "~> 3.3", ">= 3.3.2"

group :development, :test do
  gem "erb_lint"
  gem "faker"
end

group :development do
  gem "bundle-audit", require: false
  gem "hotwire-spark"
  # gem "bullet" # Uncomment if you want to use Bullet
  gem "letter_opener_web"
  gem "rails-erd"
end
