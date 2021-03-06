# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require "log4r"

module VagrantPlugins
  module Google
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_google::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env[:google_compute], env[:machine])

          @app.call(env)
        end

        def read_ssh_info(google, machine)
          return nil if machine.id.nil?
          # Find the machine
          zone = machine.provider_config.zone
          server = google.servers.get(machine.id, zone)
          if server.nil?
            # The machine can't be found
            @logger.info("Machine '#{zone}:#{machine.id}'couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end

          # Get private_ip setting
          use_private_ip = machine.provider_config.get_zone_config(zone).use_private_ip

          # Default to use public ip address
          ssh_info = {
            :host => server.public_ip_address,
            :port => 22
          }

          if use_private_ip then
            ssh_info = {
              :host => server.private_ip_address,
              :port => 22
            }
          end

          # Return SSH network info
          return ssh_info
        end
      end
    end
  end
end
