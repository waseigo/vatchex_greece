import Config

config :vatchex_greece, :globals,
  gsis_wsdl_url: "https://www1.gsis.gr/webtax2/wsgsis/RgWsPublic/RgWsPublicPort?wsdl",
  username: "",
  password: "",
  afmCalledBy: "",
  xml_template: "priv/request.xml.eex"

config :soap, :globals, version: "1.1"
