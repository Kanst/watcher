
def mongo_auth()
    client = Mongo::Connection.new # defaults to localhost:27017
    db = client['dashing']
    db.authenticate('dashing', 'WtDqAZ0J')
    return db
end
