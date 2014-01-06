## \file    modules/security/manifests/init.pp
#  \author  Scott Wales <scott.wales@unimelb.edu.au>
#  \brief
#
#  Copyright 2013 Scott Wales
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# Various security features

class security {
  include firewall
  include security::firewall_pre
  include security::firewall_post

  File {
    owner => root,
    group => root,
  }

  # Automatic updates 1 am every sunday
  cron {'yum update':
    command => '/usr/bin/yum update -y',
    user    => 'root',
    weekday => '0',
    hour    => '1',
    minute  => '0',
  }

  # Lock down root
  user {'root':
    ensure => present,
    shell  => '/sbin/nologin',
  }
  file {'/etc/securetty':
    ensure  => present,
    content => '',
  }

  # Secure files
  file {['/etc/passwd','/etc/group','/etc/fstab']:
    mode  => '0644',
  }
  file {'/etc/shadow':
    mode  => '0000',
  }
  file {'/root':
    mode  => '0500',
  }

  # Firewall defaults
  Firewall {
    require => Class['security::firewall_pre'],
    before  => Class['security::firewall_post'],
  }

  # Remove any firewall rules not defined in puppet
  resources {'firewall':
    purge => true,
  }

  firewall {'101 allow ssh':
    port   => 22,
    proto  => tcp,
    action => accept,
  }
  firewall {'102 allow http/s':
    port   => [80,443],
    proto  => tcp,
    action => accept,
  }

  # Make sure firewall is set up before pacakges are installed
  Class['security::firewall_post'] -> Yumrepo<||>
  Class['security::firewall_post'] -> Vcsrepo<||>
  Class['security::firewall_post'] -> Package<|title!='iptables'|>

}
