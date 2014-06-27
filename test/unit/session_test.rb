# encoding: utf-8
require 'test_helper'

class SessionTest < ActiveSupport::TestCase
  test 'base' do

    # create users
    roles  = Role.where( :name => [ 'Agent'] )
    groups = Group.all

    UserInfo.current_user_id = 1
    agent1 = User.create_or_update(
      :login         => 'session-agent-1',
      :firstname     => 'Session',
      :lastname      => 'Agent 1',
      :email         => 'session-agent1@example.com',
      :password      => 'agentpw',
      :active        => true,
      :roles         => roles,
      :groups        => groups,
    )
    agent2 = User.create_or_update(
      :login         => 'session-agent-2',
      :firstname     => 'Session',
      :lastname      => 'Agent 2',
      :email         => 'session-agent2@example.com',
      :password      => 'agentpw',
      :active        => true,
      :roles         => roles,
      :groups        => groups,
    )
    agent3 = User.create_or_update(
      :login         => 'session-agent-3',
      :firstname     => 'Session',
      :lastname      => 'Agent 3',
      :email         => 'session-agent3@example.com',
      :password      => 'agentpw',
      :active        => true,
      :roles         => roles,
      :groups        => groups,
    )

    # create sessions
    client_id1 = '1234'
    client_id2 = '123456'
    client_id3 = 'abc'
    Sessions.destory(client_id1)
    Sessions.destory(client_id2)
    Sessions.destory(client_id3)
    Sessions.create( client_id1, agent1.attributes, { :type => 'websocket' } )
    Sessions.create( client_id2, agent2.attributes, { :type => 'ajax' } )
    Sessions.create( client_id3, agent3.attributes, { :type => 'ajax' } )

    # check if session exists
    assert( Sessions.session_exists?(client_id1), "check if session exists" )
    assert( Sessions.session_exists?(client_id2), "check if session exists" )
    assert( Sessions.session_exists?(client_id3), "check if session exists" )

    # check if session still exists after idle cleanup
    sleep 1
    Sessions.destory_idle_sessions(1)
    assert( Sessions.session_exists?(client_id1), "check if session exists after 1 sec" )
    assert( Sessions.session_exists?(client_id2), "check if session exists after 1 sec" )
    assert( Sessions.session_exists?(client_id3), "check if session exists after 1 sec" )



    # check client threads


    # check worker threads



    # check if session still exists after idle cleanup with touched sessions
    sleep 62
    Sessions.touch(client_id1)
    Sessions.touch(client_id2)
    Sessions.touch(client_id3)
    Sessions.destory_idle_sessions(1)
    assert( Sessions.session_exists?(client_id1), "check if session exists after touch" )
    assert( Sessions.session_exists?(client_id2), "check if session exists after touch" )
    assert( Sessions.session_exists?(client_id3), "check if session exists after touch" )

    # check session data
    data = Sessions.get(client_id1)
    assert( data[:meta], "check if meta exists" )
    assert( data[:user], "check if user exists" )
    assert_equal( data[:user][:id], agent1.id, "check if user id is correct" )

    data = Sessions.get(client_id2)
    assert( data[:meta], "check if meta exists" )
    assert( data[:user], "check if user exists" )
    assert_equal( data[:user][:id], agent2.id, "check if user id is correct" )

    data = Sessions.get(client_id3)
    assert( data[:meta], "check if meta exists" )
    assert( data[:user], "check if user exists" )
    assert_equal( data[:user][:id], agent3.id, "check if user id is correct" )

    # send data to one client
    Sessions.send( client_id1, { :msg => 'äöüß123' } )
    Sessions.send( client_id1, { :msg => 'äöüß1234' } )
    messages = Sessions.queue(client_id1)
    assert_equal( 3, messages.count, 'messages count')
    assert_equal( 'ws:login', messages[0]['event'], 'messages 1')
    assert_equal( true, messages[0]['data']['success'], 'messages 1')
    assert_equal( 'äöüß123', messages[1]['msg'], 'messages 2')
    assert_equal( 'äöüß1234', messages[2]['msg'], 'messages 3')

    messages = Sessions.queue(client_id2)
    assert_equal( messages.count, 1, 'messages count')
    assert_equal( 'ws:login', messages[0]['event'], 'messages 1')
    assert_equal( true, messages[0]['data']['success'], 'messages 1')

    messages = Sessions.queue(client_id3)
    assert_equal( messages.count, 1, 'messages count')
    assert_equal( 'ws:login', messages[0]['event'], 'messages 1')
    assert_equal( true, messages[0]['data']['success'], 'messages 1')


    # broadcast to all clients
    Sessions.broadcast( { :msg => 'ooo123123123123123123'} )
    messages = Sessions.queue(client_id1)
    assert_equal( messages.count, 1, 'messages count')
    assert_equal( 'ooo123123123123123123', messages[0]['msg'], 'messages broadcast 1')

    messages = Sessions.queue(client_id2)
    assert_equal( messages.count, 1, 'messages count')
    assert_equal( 'ooo123123123123123123', messages[0]['msg'], 'messages broadcast 1')

    messages = Sessions.queue(client_id3)
    assert_equal( messages.count, 1, 'messages count')
    assert_equal( 'ooo123123123123123123', messages[0]['msg'], 'messages broadcast 1')


    # check client threads


    # check worker threads


    # check if session still exists after idle cleanup
    sleep 62
    client_ids = Sessions.destory_idle_sessions(1)

    # check client sessions
    assert( !Sessions.session_exists?(client_id1), "check if session is removed" )
    assert( !Sessions.session_exists?(client_id2), "check if session is removed" )
    assert( !Sessions.session_exists?(client_id3), "check if session is removed" )

    # check client threads


    # check worker threads



  end
end
