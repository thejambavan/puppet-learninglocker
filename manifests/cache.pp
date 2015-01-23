class learninglocker::cache (
) {
  include ius

  class { 'redis':
    system_sysctl => true,
    redis_version_override => '2.4.x',
    require => [Yumrepo['epel']],
  }
}
