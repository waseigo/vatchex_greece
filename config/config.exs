import Config

config :vatchex_greece, :globals,
  gsis_wsdl_url: "https://www1.gsis.gr/webtax2/wsgsis/RgWsPublic/RgWsPublicPort?wsdl",
  xml_template: "priv/request.xml.eex",
  username: "",
  password: "",
  afmCalledBy: ""

config :soap, :globals, version: "1.1"
