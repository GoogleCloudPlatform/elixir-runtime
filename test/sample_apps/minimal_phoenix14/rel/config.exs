use Distillery.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"fHz/NVBV6lbI<s$enmNsSQ^0J*I}17LHoYqS&YztOKYW/|E&b@$9;cI`P5E1(KfQ"
end

environment :staging do
  set include_erts: true
  set include_src: false
  set cookie: :"fHz/NVBV6lbI<s$enmNsSQ^0J*I}17LHoYqS&YztOKYW/|E&b@$9;cI`P5E1(KfQ"
end

release :minimal_phoenix14 do
  set version: current_version(:minimal_phoenix14)
  set applications: [
    :runtime_tools
  ]
end
