%global cookbook_path /var/chef/cookbooks/rb-ai

Name: cookbook-rb-ai
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Summary: Redborder cookbook to install and configure redborder-rb-ai

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-rb-ai
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}%{cookbook_path}
cp -f -r  resources/* %{buildroot}%{cookbook_path}
chmod -R 0755 %{buildroot}%{cookbook_path}
install -D -m 0644 README.md %{buildroot}%{cookbook_path}/README.md

%pre

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload rb-ai'
  ;;
esac

%files
%defattr(0755,root,root)
%{cookbook_path}
%defattr(0644,root,root)
%{cookbook_path}/README.md

%doc

%changelog
* Wed Jul 24 2024 Pablo Pérez <pperez@redborder.com>
- first spec version