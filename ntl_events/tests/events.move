

  #[test_only]
  module ntl_events::events_test {
  use sui::test_scenario::{Self, ctx};
  use std::debug::{print};
  use ntl_events::events::{Self,create_event,EventsHub ,EventOrganizerCap,AdminCap};
  // use sui::url::{Self};
  use std::string::{utf8};
   #[test]
   fun test_create_event() {
   let admin = @0xAD;
   let user1 = @0x1;
   let user2 = @0x2;
   let scenario_val = test_scenario::begin(admin);
   let scenario = &mut scenario_val;
   {
    events::test_init(ctx(scenario));
   };
  test_scenario::next_tx(scenario,user1);
   {   
  let events_hub = test_scenario::take_shared<EventsHub>(scenario);
  let events_mut = &mut events_hub;
   create_event(events_mut, utf8(b"Event 1"), utf8(b"The first Sui Event"),utf8(b"htttppp"),1234,2345,utf8(b"Thanh pho HoChi Minh"),1,0,test_scenario::ctx(scenario)) ;
   test_scenario::return_shared<EventsHub>(events_hub);
   };
  test_scenario::end(scenario_val);
  }
  


   }
    

