pragma solidity ^0.5.0;

contract TicketingSystem{

    mapping(uint => artist) public artistsRegister;
    mapping(uint => venue) public venuesRegister;
    mapping(uint=> concert) public concertsRegister;
    mapping(uint => ticket) public ticketsRegister;
    struct artist{
        bytes32 name;
        uint256 artistCategory;
        address payable owner;
        uint totalTicketSold;
    }
    struct venue{
        bytes32 name;
        uint capacity;
        uint standardComission;
        address payable owner;
    }
    struct concert{
        uint artistId;
        uint venueId;
        uint concertDate;
        bool validatedByArtist;
        bool validatedByVenue;
        uint ticketPrice;
        uint totalSoldTicket;
        uint totalMoneyCollected;
    }
    struct ticket{
        address payable owner;
        bool isAvailable;
        uint concertId;
        uint amountPaid;
        bool isAvailableForSale;
        uint proposedPrice;
    }
    uint private nb_artist =1;
    uint private nb_venue = 1;
    uint private nb_concert = 1;
    uint private nb_ticket = 1;
    function createArtist(bytes32 name, uint256 category) public{
        artistsRegister[nb_artist] = artist(name,category,msg.sender,0);
        nb_artist += 1;
    }

    function modifyArtist(uint _artistId, bytes32 _name, uint _artistCategory, address payable _newOwner)public{
        require(artistsRegister[_artistId].owner == msg.sender,"Must be the owner of the artist");
        artistsRegister[_artistId].name = _name;
        artistsRegister[_artistId].artistCategory = _artistCategory;
        artistsRegister[_artistId].owner = _newOwner;
    }

    function createVenue(bytes32 _name, uint _capacity, uint _standardComission) public{
        venuesRegister[nb_venue] = venue(_name, _capacity, _standardComission, msg.sender);
        nb_venue += 1;
    }
    
    function modifyVenue(uint _venueId, bytes32 _name, uint _capacity, uint _standardComission, address payable _newOwner)public{
        require(venuesRegister[_venueId].owner == msg.sender,"Must be the owner of the venue");
        venuesRegister[_venueId].name = _name;
        venuesRegister[_venueId].capacity = _capacity;
        venuesRegister[_venueId].owner = _newOwner;
        venuesRegister[_venueId].standardComission = _standardComission;
    }

    function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice) public{
        if(msg.sender == artistsRegister[_artistId].owner)
        {
            concertsRegister[nb_concert] = concert(_artistId, _venueId, _concertDate, true, false, _ticketPrice, 0, 0);
        }
        else{
            concertsRegister[nb_concert] = concert(_artistId, _venueId, _concertDate, false, false, _ticketPrice, 0, 0);
        }
        nb_concert += 1;
    }

    function validateConcert(uint _concertId) public{
        if(artistsRegister[concertsRegister[_concertId].artistId].owner == msg.sender){
            concertsRegister[_concertId].validatedByArtist = true;
        }
        if(venuesRegister[concertsRegister[_concertId].venueId].owner == msg.sender){
            concertsRegister[_concertId].validatedByVenue = true;
        }
    }

    function emitTicket(uint _concertId, address payable _ticketOwner)public{
        require(artistsRegister[concertsRegister[_concertId].artistId].owner == msg.sender, "Must be the artist of the concert");
        concertsRegister[_concertId].totalSoldTicket += 1;
        ticketsRegister[nb_ticket] = ticket(_ticketOwner, true, _concertId, 0, false,0);
        nb_ticket += 1;
    }

    function useTicket(uint _ticketId)public{
        require(ticketsRegister[_ticketId].owner == msg.sender,"Must be the owner of the ticket");
        require(concertsRegister[ticketsRegister[_ticketId].concertId].concertDate > now && now >= concertsRegister[ticketsRegister[_ticketId].concertId].concertDate - 24 hours ,"Ticket must be use the day of concert");
        require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByVenue == true,"Concert must be validating by venue");
        ticketsRegister[_ticketId].owner = address(0);
        ticketsRegister[_ticketId].isAvailable = false;
    }

    function buyTicket(uint _concertId) public payable{
        require(msg.value == concertsRegister[_concertId].ticketPrice,"Must send the correct price for ticket");
        concertsRegister[_concertId].totalSoldTicket += 1;
        concertsRegister[_concertId].totalMoneyCollected += msg.value;
        ticketsRegister[nb_ticket] = ticket(msg.sender, true, _concertId,msg.value, false,0);
        nb_ticket += 1;

    }

    function transferTicket(uint _ticketId, address payable _newOwner) public{
        require(ticketsRegister[_ticketId].owner == msg.sender,"Must be the owner of the ticker");
        ticketsRegister[_ticketId].owner = _newOwner;
    }
    
    function cashOutConcert(uint _concertId, address payable _cashOutAddress)public {
        require(now >= concertsRegister[_concertId].concertDate,"Concert must be over");
        require(artistsRegister[concertsRegister[_concertId].artistId].owner == msg.sender, "Must be the artist of the concert");
        uint venueShare = concertsRegister[_concertId].totalMoneyCollected * (venuesRegister[concertsRegister[_concertId].venueId].standardComission / 10000);
        uint artistShare = concertsRegister[_concertId].totalMoneyCollected - venueShare;
        _cashOutAddress.transfer(artistShare);
        venuesRegister[concertsRegister[_concertId].venueId].owner.transfer(venueShare);
        artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold += concertsRegister[_concertId].totalSoldTicket;
    }

    function  offerTicketForSale(uint _ticketId, uint _salePrice) public{
        require(ticketsRegister[_ticketId].owner == msg.sender,"Must be the owner of the ticket");
        require(ticketsRegister[_ticketId].amountPaid >= _salePrice, "Must be sold for less than buy");
        ticketsRegister[_ticketId].isAvailableForSale = true;
        ticketsRegister[_ticketId].proposedPrice = _salePrice;
    }

    function  buySecondHandTicket(uint _ticketId) public payable{
        require(msg.value >= ticketsRegister[_ticketId].proposedPrice,"Must buy at the correct price");
        require(ticketsRegister[_ticketId].isAvailable == true,"Must be a valid ticket");
        ticketsRegister[_ticketId].owner.transfer(msg.value);
        ticketsRegister[_ticketId].owner = msg.sender;
    }
}