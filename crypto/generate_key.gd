extends Node

func _ready() -> void:
	var crypto = Crypto.new()
	var key = CryptoKey.new()
	var cert = X509Certificate.new()
	
	key = crypto.generate_rsa(4096)
	cert = crypto.generate_self_signed_certificate(key, "CN=localhost.com, 0=HuikkeProjection, C=FI")

	key.save("res://crypto/server_key.key")
	cert.save("res://crypto/server_cas.crt")
