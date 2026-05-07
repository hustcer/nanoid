// OS entropy shim for the native MoonBit backend.

#include <stddef.h>
#include <stdint.h>

#include <moonbit.h>

#if defined(_WIN32)
#include <bcrypt.h>
#include <windows.h>
#pragma comment(lib, "bcrypt.lib")

static int nanoid_os_random_impl(uint8_t *buf, size_t len) {
  if (len == 0) {
    return 0;
  }
  NTSTATUS status = BCryptGenRandom(
    NULL, buf, (ULONG)len, BCRYPT_USE_SYSTEM_PREFERRED_RNG);
  return status == 0 ? 0 : -1;
}

#elif defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || \
  defined(__NetBSD__)
#include <stdlib.h>

static int nanoid_os_random_impl(uint8_t *buf, size_t len) {
  if (len == 0) {
    return 0;
  }
  arc4random_buf(buf, len);
  return 0;
}

#elif defined(__linux__)
#include <errno.h>
#include <fcntl.h>
#include <sys/syscall.h>
#include <unistd.h>

static int nanoid_fill_fd(int fd, uint8_t *buf, size_t len) {
  while (len > 0) {
    ssize_t read_len = read(fd, buf, len);
    if (read_len > 0) {
      buf += (size_t)read_len;
      len -= (size_t)read_len;
    } else if (read_len == -1 && errno == EINTR) {
      continue;
    } else {
      return -1;
    }
  }
  return 0;
}

static int nanoid_linux_getrandom(uint8_t *buf, size_t len) {
#ifdef SYS_getrandom
  while (len > 0) {
    long read_len = syscall(SYS_getrandom, buf, len, 0);
    if (read_len > 0) {
      buf += (size_t)read_len;
      len -= (size_t)read_len;
    } else if (read_len == -1 && errno == EINTR) {
      continue;
    } else if (read_len == -1 && errno == ENOSYS) {
      return -2;
    } else {
      return -1;
    }
  }
  return 0;
#else
  (void)buf;
  (void)len;
  return -2;
#endif
}

static int nanoid_os_random_impl(uint8_t *buf, size_t len) {
  if (len == 0) {
    return 0;
  }

  int result = nanoid_linux_getrandom(buf, len);
  if (result == 0) {
    return 0;
  }
  if (result == -1) {
    return -1;
  }

  int fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
  if (fd < 0) {
    return -1;
  }
  int ok = nanoid_fill_fd(fd, buf, len);
  int saved_errno = errno;
  close(fd);
  errno = saved_errno;
  return ok;
}

#else
#error "Unsupported native platform: add an OS entropy source for nanoid."
#endif

int nanoid_os_random(moonbit_bytes_t buf, int len) {
  if (len < 0) {
    return -1;
  }
  return nanoid_os_random_impl((uint8_t *)buf, (size_t)len);
}
