component "openssl" do |pkg, settings, platform|
  pkg.version "1.0.0q"
  pkg.md5sum "8cafccab6f05e8048148e5c282ed5402"
  pkg.url "http://buildsources.delivery.puppetlabs.net/openssl-#{pkg.get_version}.tar.gz"

  # use pkg.replaces to handle both of the following
  # pkg.replaces "pe-openssl"
  #
  #pkg.obsoletes (replaces)
  #pkg.conflicts

  pkg.configure do
    [# OpenSSL Configure doesn't honor CFLAGS or LDFLAGS as environment variables.
    # Instead, those should be passed to Configure at the end of its options, as
    # any unrecognized options are passed straight through to ${CC}. Defining
    # --libdir ensures that we avoid the multilib (lib/ vs. lib64/) problem,
    # since configure uses the existence of a lib64 directory to determine
    # if it should install its own libs into a multilib dir. Yay OpenSSL!
    "./Configure \
      --prefix=#{settings[:prefix]} \
      --libdir=lib \
      --openssldir=#{settings[:prefix]}/ssl \
      shared \
      linux-elf \
      no-asm 386 \
      no-camellia \
      enable-seed \
      enable-tlsext \
      enable-rfc3779 \
      enable-cms \
      no-md2 \
      no-mdc2 \
      no-rc5 \
      no-ec2m \
      no-gost \
      no-srp \
      no-ssl2 \
      no-ssl3 \
      #{settings[:cflags]} \
      #{settings[:ldflags]} -Wl,-z,relro"]
  end

  if platform.is_deb?
    linking = "ln -s /etc/ssl/certs/ca-certificates.crt '#{settings[:prefix]}/ssl/cert.pem'"
  elsif platform.is_rpm?
    case platform[:name]
    when /sles-10-.*$/, /sles-11-.*$/
      linking = "pushd '#{settings[:prefix]}/ssl/certs' 2>&1 >/dev/null; find /etc/ssl/certs -type f -a -name '\*pem' -print0 | xargs -0 --no-run-if-empty -n1 ln -sf; /usr/bin/c_rehash ."
    when /sles-12-.*$/
      linking = "ln -s /etc/ssl/ca-bundle.pem '#{settings[:prefix]}/ssl/cert.pem'"
    when /el-4-.*$/
      linking = "ln -s /usr/share/ssl/certs/ca-bundle.crt '#{settings[:prefix]}/ssl/cert.pem'"
    else
      linking = "ln -s /etc/pki/tls/certs/ca-bundle.crt '#{settings[:prefix]}/ssl/cert.pem'"
    end
  end

=begin
  if platform.is_deb?
    pkg.link "/etc/ssl/certs/ca-certificates.crt", "#{settings[:prefix]}/ssl/cert.pem"
  elsif platform.is_rpm?
    pkg.link "/etc/pki/tls/certs/ca-bundle.crt", "#{settings[:prefix]}/ssl/cert.pem"
  end
=end

  pkg.build do
    ["#{platform[:make]} depend",
    "#{platform[:make]}"]
  end

  pkg.install do
    ["#{platform[:make]} INSTALL_PREFIX=/ install",
    linking]
  end
end
