

  #[test_only]
  module ntl_events::events_test {
  use sui::test_scenario::{Self, ctx,};
  use std::debug::{print};
  use ntl_events::events::{Self,create_event,EventsHub ,EventOrganizerCap,AdminCap,EventInfo};
  use std::string::utf8;
  use sui::test_scenario::Scenario;
  use sui::clock;
  
    const ADMIN: address = @0xA11CE;
    const USER_1: address = @0x923E;
    const USER_2: address = @0x003E;
    const USER_3: address = @0x228E;

   #[test]
   fun test_create_event() {
   let scenario_val = test_scenario::begin(ADMIN);
   let scenario = &mut scenario_val;
   let ctx = test_scenario::ctx(scenario);
   events::init_for_testing(ctx);

   test_scenario::next_tx(scenario,USER_1); 

   let events_hub = test_scenario::take_shared<EventsHub>(scenario);
   let events_mut = &mut events_hub;
   let clock = clock::create_for_testing(ctx(scenario));
   clock::increment_for_testing(&mut clock, 60000);

   create_event(events_mut, utf8(b"Event 1"), utf8(b"The first Sui Event"),utf8(b"httt://ppp"),180000,600000,900000,1200000,utf8(b"Thanh pho HoChi Minh"),1,0,&clock,test_scenario::ctx(scenario));
   test_scenario::return_shared<EventsHub>(events_hub);
  //  test_scenario::return_shared<EventInfo>(event);
   clock::destroy_for_testing(clock);
   test_scenario::end(scenario_val);
  }
  #[test]
    #[expected_failure(abort_code = events::ERR_OPENING_DATE_FOR_SALE)]
    fun create_event_failure() {
      let scenario_val = test_scenario::begin(ADMIN);
      let scenario = &mut scenario_val;
      let ctx = test_scenario::ctx(scenario);
      events::init_for_testing(ctx);
   
      test_scenario::next_tx(scenario,USER_1); 
   
      let events_hub = test_scenario::take_shared<EventsHub>(scenario);
      let events_mut = &mut events_hub;
      let clock = clock::create_for_testing(ctx(scenario));
      clock::increment_for_testing(&mut clock, 171086956323456);
      create_event(events_mut, utf8(b"Event 1"), utf8(b"The first Sui Event"),utf8(b"httt://ppp"),1710869563,1710869963580,1715869963580,1730869963580,utf8(b"Thanh pho HoChi Minh"),1,0,&clock,test_scenario::ctx(scenario));
   
     test_scenario::return_shared<EventsHub>(events_hub);
  //  test_scenario::return_shared<EventInfo>(event);
     clock::destroy_for_testing(clock);
     test_scenario::end(scenario_val);
    }





  // ====== Utility functions ======
   }
    

