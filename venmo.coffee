request = require 'request'
makePayment: (from_token, to_userid, message, amount) ->
	data = {
		'access_token': from_token,
		'user_id': to_userid,
		'note': message,
		'amount': amount
	}
	request.post('https://api.venmo.com/payments', {form: data}, (e, r, data) ->
		console.log e
		console.log r
		console.log data
		if (data.error)
			return false
		else
			return true
	)

