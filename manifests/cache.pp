class learninglocker::cache (
) {
  class { 'redis':
    system_sysctl => true
  }
}
