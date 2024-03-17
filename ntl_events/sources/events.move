#[allow(unused_field)]
module ntl_events::events{
    use sui::package;
    use sui::display;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext,sender};
    use std::string::{Self,utf8, String};
    use sui::clock::{Self, Clock};
    use sui::event::{emit};
    use sui::url::{Self,Url};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use std::option::{Self,Option};
    use sui::address;
    use sui::coin::{Self,Coin};
    use sui::transfer::{transfer, public_transfer, share_object};
    use sui::dynamic_object_field as dof;
    use std::vector;
    use sui::object_table::{Self, ObjectTable};

   

    const ERR_EVENT_NOT_FOUND:u64 = 0;
    const ERR_OPENING_DATE_FOR_SALE:u64 = 1;
    const ERR_CLOSING_DATE_FOR_SALE:u64 = 2;
    const ERR_START_DATE:u64 = 3;
    const ERR_END_DATE:u64 = 4;
    const ERR_EVENT_NOT_STARTED_FORSALE:u64 = 5;
    const ERR_EVENT_HAS_CLOSED_FOR_SALE:u64 = 6;
    const ERR_EVENT_NOT_START_FOR_CHECKIN:u64 = 7;
    const ERR_EVENT_HAS_ENDED:u64 = 8;
    const ERR_USER_HAS_REGISTERED_EVENT:u64 = 9;
    const ERR_NOT_ENGOUH_FUND:u64 = 10;
    const ERR_USER_HAS_CHECKED_IN:u64 = 11;
    const ERR_USER_HAS_NOT_REGISTERED:u64 = 12;
    const ERR_ONLY_USER_REGISTERED:u64 = 13;
    const EROR_NOT_AUTHORIZED:u64 = 14;


    const EVENT_TYPE_FREE:u64 =0;
    const EVENT_TYPE_PAID:u64 =1;

    const EVENT_STATUS_REGISTED:u64 =2;
    const EVENT_STATUS_ATTENDED:u64 =3;
    

    //Event
    struct EventCreated has copy, drop {
        id: ID,
        creator: address,
    }
    struct EventUpdated has copy, drop {
        id: ID,
        creator: address,
    }
    struct EventCanceled has copy, drop {
        id: ID,
        creator: address,
    }
    struct EventRegistered has copy, drop {
        id: ID,
        user: address,
    }
    struct EventCheckedIn has copy, drop {
        id: ID,
        user: address,
    }
    struct PostCreated has copy, drop {
      id: ID,
      creator: address,
    }

    struct EVENTS has drop{}

    struct AdminCap has key{
        id:UID,
        admin:address,
    }

    struct EventOrganizerCap has key, store {
        id: UID,
        event_id: ID,
    }
    
    struct EventsHub has key{
        id:UID,

    }

    struct EventNFT has key,store{
       id:UID,
       event_id:ID,
    }

    struct Attendee has key,store{
        id:UID,
        user_address:address,
        status:u64,
    }

    struct Post has key,store{
        id:UID,
        user_id:address,
        content:String,
        media:vector<Url>,
    }

    struct EventInfo has key {
        id:UID,
        opening_day_for_sale:u64,
        closing_day_for_sale:u64,
        start_date:u64,
        end_date:u64,
        type_event:u64, 
        price:u64,
        balance:Balance<SUI>, 
        attendees:ObjectTable<address,Attendee>,
        posts:ObjectTable<ID,Post>
    } 
    struct EventListed has key,store{
        id:UID,
        event_id:ID,
        name:String,
        description:String,
        image:Url,
        opening_day_for_sale:u64,
        closing_day_for_sale:u64,
        start_date:u64,
        end_date:u64,
        location:String,
        type_event:u64,
        price:u64,
    }

    struct UserProfile has key,store {
        id:UID,
        user_id: address,
        name:Option<String>,
        avatar:Option<Url>,
        registered_events: vector<ID>,  
    }

    fun init(otw: EVENTS, ctx: &mut TxContext) {
        let creator = sender(ctx);
        let adminCap = AdminCap{ 
            id: object::new(ctx),
            admin: creator,
         };
         let eventsHub = EventsHub{
            id: object::new(ctx),
         };

        let eventsHub_keys = vector[
          utf8(b"Name"),
          utf8(b"Description"),
          utf8(b"Image Uri"),
          utf8(b"Link"),
        ];
    
        let eventsHub_values = vector[
          utf8(b"SUIEVENTS"),
          utf8(b"The app(PWA) for listing Sui or Sui-related events (ex. Luma or eventbrite) utilizing dynamic NFTs"),
          utf8(b"https://pbs.twimg.com/card_img/1766108386188464128/1lRmJNor?format=jpg&name=medium"),
          utf8(b"https://sui.io/"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<EventsHub>(&publisher, eventsHub_keys, eventsHub_values, ctx);
   
        display::update_version(&mut display);

        public_transfer(publisher, creator);
        public_transfer(display, creator);
        transfer(adminCap, creator);
        share_object(eventsHub);
    }

   public entry fun create_event (
     events_hub:&mut EventsHub,
     name:String,
     description:String,
     image:vector<u8>,
     opening_day_for_sale:u64,
     closing_day_for_sale:u64,
     start_date:u64,
     end_date:u64,
     location:String,
     type_event:u64,
     price:u64,
     clock:&Clock,
     ctx:&mut TxContext
     ){
    let creator = sender(ctx);
    let now = clock::timestamp_ms(clock);
    assert!(opening_day_for_sale >= now, ERR_OPENING_DATE_FOR_SALE);
    assert!(closing_day_for_sale > opening_day_for_sale, ERR_CLOSING_DATE_FOR_SALE);
    assert!(start_date > closing_day_for_sale, ERR_START_DATE);
    assert!(end_date > start_date, ERR_END_DATE);
    let event_id = object::new(ctx);
    let id_copy = object::uid_to_inner(&event_id);
    let event = EventInfo{
      id: event_id,
      opening_day_for_sale: opening_day_for_sale,
      closing_day_for_sale: closing_day_for_sale,
      start_date: start_date,
      end_date: end_date,
      type_event: type_event,
      price: price,
      balance: balance::zero<SUI>(),
      attendees:object_table::new<address,Attendee>(ctx),
      posts: object_table::new<ID,Post>(ctx),
    };
    let organizer_cap = EventOrganizerCap{
        id: object::new(ctx),
        event_id: object::uid_to_inner(&event.id),
     };
     share_object(event);
      emit(EventCreated {
      id: object::id(&event),
      creator,
      });
      dof::add(&mut events_hub.id, id_copy, EventListed{
        id: object::new(ctx),
        event_id: id_copy,
        name: name,
        description: description,
        image: url::new_unsafe_from_bytes(image),
        opening_day_for_sale: opening_day_for_sale,
        closing_day_for_sale: closing_day_for_sale,
        start_date: start_date,
        end_date: end_date,
        location: location,
        type_event: type_event,
        price: price,
      });
      public_transfer(organizer_cap, creator);
    }

    public entry fun register_event(
        event_mut: &mut EventInfo,
        clock: &Clock,
        amount:Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let user = sender(ctx);
        let now = clock::timestamp_ms(clock);
        assert!(now >= event_mut.opening_day_for_sale,ERR_EVENT_NOT_STARTED_FORSALE );
        assert!(now < event_mut.closing_day_for_sale,ERR_EVENT_HAS_CLOSED_FOR_SALE);
        assert!(!checkUserRegisteredEvent(event_mut,user),ERR_USER_HAS_REGISTERED_EVENT);
        let value = coin::value(&amount);
        assert!(value >= event_mut.price,ERR_NOT_ENGOUH_FUND);
        let balance_input = coin::into_balance(amount);
        balance::join(&mut event_mut.balance, balance_input);
        let eventNft = EventNFT{
          id: object::new(ctx),
          event_id:object::uid_to_inner(&event_mut.id),
        };
        public_transfer(eventNft,user);
        object_table::add(&mut event_mut.attendees, user, Attendee{
          id: object::new(ctx),
          user_address: user,
          status: EVENT_STATUS_REGISTED,
        });

        // if(event_mut.type_event == EVENT_TYPE_PAID){
        //   assert!(value == event_mut.price,ERR_NOT_ENGOUH_FUND);
        //   let balance_input = coin::into_balance(amount);
        //   balance::join(&mut event_mut.balance, balance_input);
        //   let eventNft = EventNFT{
        //     id: object::new(ctx),
        //     name: event_mut.name,
        //     description: event_mut.description,
        //     image: event_mut.image,
        //     location: event_mut.location,
        //   };
        //   let nft_id = object::id(&eventNft);
        //   transfer(eventNft, user);
        //   vector::push_back(&mut event_mut.registed, user);
        //   linked_table::push_front(&mut event_mut.attendees, nft_id, Attendee{
        //     id: object::new(ctx),
        //     event_id: event_id,
        //     user_id: user,
        //     status: EVENT_STATUS_REGISTED,
        //   });
        //   if(checkUserExist(&mut events_hub.id, user)){
        //     let user_profile = dof::borrow_mut<address,UserProfile>(&mut events_hub.id, user);
        //     vector::push_back(&mut user_profile.registered_events, event_id);
        //   }else{
        //     let user_profile = UserProfile{
        //       id:object::new(ctx),
        //       user_id: user,
        //       name:option::none<String>(),
        //       avatar:option::none<Url>(),
        //       registered_events: vector::empty<ID>(),
        //     };
        //     vector::push_back(&mut user_profile.registered_events, event_id);
        //     dof::add(&mut events_hub.id, user, user_profile);
        //   }
        // } else {
        //   let balance_input = coin::into_balance(amount);
        //   balance::join(&mut event_mut.balance, balance_input);
        //   let eventNft = EventNFT{
        //     id: object::new(ctx),
        //     name: event_mut.name,
        //     description: event_mut.description,
        //     image: event_mut.image,
        //     location: event_mut.location,
        //   };
        //   let nft_id = object::id(&eventNft);
        //   transfer(eventNft, user);
        //   vector::push_back(&mut event_mut.registed, user);
        //   linked_table::push_front(&mut event_mut.attendees, nft_id, Attendee{
        //     id: object::new(ctx),
        //     event_id: event_id,
        //     user_id: user,
        //     status: EVENT_STATUS_REGISTED,
        //   });
        //   if(checkUserExist(&mut events_hub.id, user)){
        //     let user_profile = dof::borrow_mut<address,UserProfile>(&mut events_hub.id, user);
        //     vector::push_back(&mut user_profile.registered_events, event_id);
        //   }else{
        //     let user_profile = UserProfile{
        //       id:object::new(ctx),
        //       user_id: user,
        //       name:option::none<String>(),
        //       avatar:option::none<Url>(),
        //       registered_events: vector::empty<ID>(),
        //     };
        //     vector::push_back(&mut user_profile.registered_events, event_id);
        //     dof::add(&mut events_hub.id, user, user_profile);
        //   }
        // };
        
    }
    
    public entry fun checkin_event(
        event_mut: &mut EventInfo,
        clock:&Clock,
        ctx: &mut TxContext,
    ) { 
        let now = clock::timestamp_ms(clock);
        let user = sender(ctx);
        assert!(now >= event_mut.start_date,ERR_EVENT_NOT_START_FOR_CHECKIN);
        assert!(now < event_mut.end_date,ERR_EVENT_HAS_ENDED);
        assert!(checkUserRegisteredEvent(event_mut,user),ERR_USER_HAS_NOT_REGISTERED);
        let attendee = object_table::borrow_mut<address,Attendee>(&mut event_mut.attendees, user);
        assert!(attendee.status != EVENT_STATUS_ATTENDED,ERR_USER_HAS_CHECKED_IN);
        attendee.status = EVENT_STATUS_ATTENDED;
  }   
   public entry fun post(
    event_mut: &mut EventInfo,
    contents: String,
    media:vector<vector<u8>>,
    ctx: &mut TxContext,
   ){
    let user = sender(ctx);
    assert!(checkUserRegisteredEvent(event_mut,user),ERR_ONLY_USER_REGISTERED);
    let length = vector::length(&media);
    let i = 0;
    let medias = vector::empty<Url>();
    while(i < length) {
      let url = url::new_unsafe_from_bytes(vector::pop_back(&mut media));
      vector::push_back(&mut medias, url);
      i = i + 1;
    };
    let post = Post{
      id: object::new(ctx),
      user_id: user,
      content:contents,
      media: medias,
    }; 
    object_table::add(&mut event_mut.posts, object::id(&post), post);
   }
   

   public entry fun edit_event(
    cap:&EventOrganizerCap,
    events_hub:&mut EventsHub,
    event:&mut EventInfo,
    name:String,
    description:String,
    image:vector<u8>,
    opening_day_for_sale:u64,
    closing_day_for_sale:u64,
    start_date:u64,
    end_date:u64,
    location:String,
    type_event:u64,
    price:u64,
    _:&mut TxContext
   )
   {
    assert!(cap.event_id == object::uid_to_inner(&event.id),EROR_NOT_AUTHORIZED);
    event.opening_day_for_sale = opening_day_for_sale;
    event.closing_day_for_sale = closing_day_for_sale;
    event.start_date = start_date;
    event.end_date = end_date;
    event.type_event = type_event;
    event.price = price;
    let event_mut = dof::borrow_mut<ID,EventListed>(&mut events_hub.id, object::uid_to_inner(&event.id));
    event_mut.name = name;
    event_mut.description = description;
    event_mut.image = url::new_unsafe_from_bytes(image);
    event_mut.opening_day_for_sale = opening_day_for_sale;
    event_mut.closing_day_for_sale = closing_day_for_sale;
    event_mut.start_date = start_date;
    event_mut.end_date = end_date;
    event_mut.location = location;
    event_mut.type_event = type_event;
    event_mut.price = price;
   }

   public entry fun cancel_event(
    cap:&EventOrganizerCap,
    admin:&AdminCap,
    event:&mut EventInfo,
    events_hub:&mut EventsHub,
    ctx:&mut TxContext
   ){
    let user = sender(ctx);
    assert!(cap.event_id == object::uid_to_inner(&event.id) || admin.address ==user,EROR_NOT_AUTHORIZED);

   }
    
  
  
  public fun checkUserRegisteredEvent(
    event_mut: &mut EventInfo,
    user: address,
): bool {
    object_table::contains(&event_mut.attendees, user)
}
   
#[test_only]
/// Wrapper of module initializer for testing
public fun test_init(ctx: &mut TxContext) {
    init(EVENTS {}, ctx)
}
  
  }
 
  