# frozen_string_literal: true

RailsHealthChecks.configure do |config|
  # Checks to run (default: [:database])
  # Available built-ins: :database, :cache, :redis, :sidekiq, :solid_queue,
  #                      :good_job, :resque, :disk, :memory, :http
  config.checks = [:database]

  # Global timeout per check in seconds (default: 5)
  config.timeout = 5

  # Cache check results for N seconds to avoid re-running on every request (default: nil, disabled)
  # config.cache_duration = 10

  # ---------------------------------------------------------------------------
  # Authentication — all strategies are mutually exclusive; default is public
  # ---------------------------------------------------------------------------

  # Bearer token: requests must include Authorization: Bearer <token>
  # config.token = ENV["HEALTH_TOKEN"]

  # IP allowlist: exact IPs or CIDR ranges
  # config.allowed_ips = ["127.0.0.1", "10.0.0.0/8"]

  # Custom block: return truthy to allow the request
  # config.authenticate { |request| request.headers["X-Internal"] == "true" }

  # ---------------------------------------------------------------------------
  # Per-environment toggling
  # ---------------------------------------------------------------------------
  # config.disable :disk,   in: :test
  # config.disable :memory, in: [:test, :development]

  # ---------------------------------------------------------------------------
  # Check groups — expose subsets at GET /health/:group
  # ---------------------------------------------------------------------------
  # config.group :system,  [:disk, :memory]
  # config.group :workers, [:sidekiq, :good_job]

  # ---------------------------------------------------------------------------
  # Redis check (requires :redis in config.checks and the redis gem)
  # ---------------------------------------------------------------------------
  # config.redis_url = ENV["REDIS_URL"]         # default: redis://localhost:6379/0

  # ---------------------------------------------------------------------------
  # Disk check (requires :disk in config.checks)
  # ---------------------------------------------------------------------------
  # config.disk_path               = "/"             # mount point (default: "/")
  # config.disk_warn_threshold     = 2 * 1024**3     # bytes free → degraded
  # config.disk_critical_threshold = 512 * 1024**2   # bytes free → critical

  # ---------------------------------------------------------------------------
  # Memory check (requires :memory in config.checks)
  # ---------------------------------------------------------------------------
  # config.memory_threshold = 512 * 1024**2          # RSS bytes → degraded

  # ---------------------------------------------------------------------------
  # HTTP check (requires :http in config.checks)
  # ---------------------------------------------------------------------------
  # config.http_url             = "https://api.example.com/status"
  # config.http_expected_status = 200                # expected response code (default: 200)
  # config.http_headers         = { "Authorization" => "Bearer #{ENV['API_TOKEN']}" }

  # ---------------------------------------------------------------------------
  # Sidekiq check (requires :sidekiq in config.checks)
  # ---------------------------------------------------------------------------
  # config.sidekiq_queue_size = 1000                 # total depth → degraded

  # ---------------------------------------------------------------------------
  # Solid Queue check (requires :solid_queue in config.checks)
  # ---------------------------------------------------------------------------
  # config.solid_queue_job_count = 500               # pending jobs → degraded

  # ---------------------------------------------------------------------------
  # GoodJob check (requires :good_job in config.checks)
  # ---------------------------------------------------------------------------
  # config.good_job_latency = 300                    # seconds oldest job waiting → degraded

  # ---------------------------------------------------------------------------
  # Resque check (requires :resque in config.checks)
  # ---------------------------------------------------------------------------
  # config.resque_queue_size = 1000                  # total depth → degraded

  # ---------------------------------------------------------------------------
  # Custom checks
  # ---------------------------------------------------------------------------
  # class MyApiCheck < RailsHealthChecks::Check
  #   def call
  #     res = Net::HTTP.get_response(URI("https://api.example.com/status"))
  #     res.code == "200" ? pass : fail_with("API returned #{res.code}")
  #   end
  # end
  #
  # config.register :my_api, MyApiCheck.new
  # config.register :slow_api, MyApiCheck.new, timeout: 10  # per-check timeout override
end
