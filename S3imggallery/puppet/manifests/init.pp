class s3imggal
{
  package {'gcc-c++':
    ensure   => 'installed',
  } ->
  package {'ruby-devel':
    ensure   => 'installed',    
  } ->
   package { 'bundler':
    ensure   => 'installed',
    provider => 'gem',
  } ->
   package { 'rack':
    ensure   => 'installed',
    provider => 'gem',
  } ->
   package { 's3':
    ensure   => 'installed',
    provider => 'gem',
  } ->
   package { 'thin':
    ensure   => 'installed',
    provider => 'gem',
  }
  file{'/opt/company/utils/s3imggal/':
      ensure => directory,
  }->
  file { '/opt/company/utils/s3imggal/s3img.rb':
    ensure => present,
    source => 'puppet:///modules/s3imggal/s3img.rb',
  }->
   file { '/opt/company/utils/s3imggal/vars.rb':
    ensure => present,
    content => template('s3imggal/vars.rb.erb'),
  }->
   file { '/opt/company/utils/s3imggal/img.css':
    ensure => present,
    source => 'puppet:///modules/s3imggal/img.css',
  }->
  file { '/etc/init/s3imggal.conf':
    ensure => present,
    source => 'puppet:///modules/s3imggal/s3imggal.conf'
  }
  service { 's3imggal':
    ensure => running,
    hasstatus => false,
    pattern => '/opt/company/utils/s3imggal/s3img.rb',
    start => '/sbin/start s3imggal',
    stop => '/sbin/stop s3imggal',
    restart => '/sbin/restart s3imggal',
    require => File['/etc/init/s3imggal.conf'],
  }
}
