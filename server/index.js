const express = require('express');
var bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
//import { v4 as uuidv4 } from 'uuid';
const app = express();
const router = express.Router();
const port = 3000;
app.use(bodyParser.json()); // support json encoded bodies

/*
 {
  "12" : {
    "creationTime" : "1232131231"
    "isComplete" : false,
    "orderId" : "fdsfdfsdf",
    "orderItems" : [
      {
        "imgUrl" : "",
        "name" : "",
        "price" : 123,
        "quantity" : 1
      }
    ]
  }
}
*/

let currentOrders = {
}

let allOrders =  {
}

let allMessages = {
}

let allMenu = [  
    { 
      "Id": "1",
      "name" : "Gyro Plate",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/Chicken-Marsala-gv-590X365.jpg",
      "price" : 12.99,
      "description": "Comes with one skewer of chicken kabob, one skewer of lamb kabob, and one piece of kafta.",
      "type" : "Plates"
    },
    {
      "Id": "2",
      "name" : "Chicken Marsala",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/Chicken-Marsala-gv-590X365.jpg",
      "price" : 10.99,
      "description": "Lightly floured grilled chicken breasts topped with savory mushroom and marsala wine sauce. Served with a side of fettuccine alfredo..",
      "type" : "Plates"
    },
    {
      "Id": "3",
      "name" : "Chicken Parmigiana",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/chicken-and-shrimp-carbonara-dpv-590x365.jpg",
      "price" : 19.99,
      "description": "Two lightly fried parmesan-breaded chicken breasts are smothered with Olive Garden’s homemade marinara sauce and melted Italian cheeses. We serve our Chicken Parmigiana with a side of spaghetti for dinner. Try this classic pairing of Italian comfort foods that will leave you saying 'yum!'.",
      "type" : "Plates"
      
    },
    {
      "Id": "4",
      "name" : "Chicken and Shrimp Carbonara",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/dinner-chicken-parm-dpv-590x365.jpg",
      "price" : 15.99,
      "description": "Sautéed seasoned chicken, shrimp and spaghetti tossed in a creamy sauce with bacon and roasted red peppers..",
      "type" : "Plates"
    },
    { 
      "Id": "5",
      "name" : "Stuffed Ziti Fritta",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/stuffed-ziti-fritta-appetizer-dpv-590x365.jpg",
      "price" : 12.99,
      "description": "Crispy fried ziti filled with five cheeses. Served with alfredo and marinara dipping sauces.",
      "type" : "Sides"
    },
    {
      "Id": "6",
      "name" : "Toasted Ravioli",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/h-pronto-lunch-soup-salad-breadsticks-208x180.jpg",
      "price" : 12.99,
      "description": "Ligtly fried ravioli filled with seasoned beef. Served with marinara sauce..",
      "type" : "Sides"
    },
    {
      "Id": "7",
      "name" : "Extra Breadsticks!",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/og-soup-salad-breadsticks-tgc-208x180.jpg",
      "price" : 4.99,
      "description": "Enjoy a freshly-baked, Olive Garden Favorite. Add an extra dozen or half dozen breadsticks to your online order.",
      "type" : "Sides"
    },
    {
      "Id": "8",
      "name" : "Spinach-Artichoke Dip",
      "imgUrl" : "https://media.olivegarden.com/images/site/h-dinner-chicken-chicken-alfredo-208x180.jpg",
      "price" : 10.99,
      "description": "A blend of spinach, artichokes and five cheeses served warm with NEW flatbread crisps, tossed with parmesan and garlic salt.",
      "type" : "Sides"
    },
    {
      "Id": "9",
      "name" : "Tiramisu (V)",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/tiramisu-dpv-590x365.jpg",
      "price" : 8.49,
      "description": "The classic Italian dessert. A layer of creamy custard set atop espresso-soaked ladyfingers.",
      "type" : "Desserts"
    },
    {
      "Id": "10",
      "name" : "Chocolate Brownie Lasagna",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/chocolate-brownie-lasagna-dpv-590x365.jpg",
      "price" : 12.99,
      "description": "Eight decadent layers of rich, fudgy brownie and sweet vanilla cream cheese frosting, topped with chocolate shavings and a chocolate drizzle..",
      "type" : "Desserts"
    },
    {
      "Id": "11",
      "name" : "Sicilian Cheesecake with Strawberry Topping (V)",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/seasonal-sicilian-cheesecake-dpv-590x365.jpg",
      "price" : 8.79,
      "description": "Riccotta cheesecake with a shortbread cookie crust, topped with seasonal strawberry sauce.",
      "type" : "Desserts"
    },
    {
      "Id": "12",
      "name" : "DolChini",
      "imgUrl" : "https://media.olivegarden.com/en_us/images/product/black-tie-mousse-cake-dpv-590x365.jpg",
      "price" : 12.99,
      "description": "Piccoli Dolci \"little dessert treats\", layered with cake, mousse, pastry creams and berries..",
      "type" : "Desserts"
    },
  ]


let myvalue = 1;


// all routes prefixed with /api
app.use('/api', router);

// using router.get() to prefix our path
// url: http://localhost:3000/api/
router.get('/', (request, response) => {
  response.json({message: 'Hello, welcome to my server'});
});

// Generate New Table Order Id
router.post('/table/:tableId', (request, response) => {
  var tableNo = request.params.tableId;
  
  console.log(tableNo)
  const now = new Date()  
  const utcMilllisecondsSinceEpoch = now.getTime() + (now.getTimezoneOffset() * 60 * 1000) 
  let tableOrder = currentOrders[tableNo]

  if(tableOrder == undefined)
  {
    currentOrders[tableNo] = {
      "creationTime" : utcMilllisecondsSinceEpoch.toString(),
      "isComplete" : false,
      "isPaid" : false,
      "orderId" : uuidv4(),
      "tableNo" : tableNo,
      "orderItems" : [
      ]
    }

    allOrders[currentOrders[tableNo]["orderId"]] = currentOrders[tableNo]

    response.json({"status" : "Success", "orderId" : currentOrders[tableNo]["orderId"]})
  }
  else
  {
    response.json({"status" : "Failure"})
  }
});

router.post('/table/:tableId/add', (request, response) => {
  var tableNo = request.params.tableId;
  var body = request.body
  
  let tableOrder = currentOrders[tableNo]
  if(tableOrder == undefined)
  {
    const now = new Date()  
    const utcMilllisecondsSinceEpoch = now.getTime() + (now.getTimezoneOffset() * 60 * 1000)  

    currentOrders[tableNo] = {
      "creationTime" : utcMilllisecondsSinceEpoch.toString(),
      "isComplete" : false,
      "isPaid" : false,
      "orderId" : uuidv4(),
      "tableNo" : tableNo,
      "orderItems" : [
      ]
    }

    allOrders[currentOrders[tableNo]["orderId"]] = currentOrders[tableNo]
  }

  currentOrders[tableNo]["orderItems"].push(body)

  response.json({"status" : "Success"})  
});

// Get Table's Status
router.get('/table/:tableId', (request, response)=> {
  var tableNo = request.params.tableId;
  
  let tableOrder = currentOrders[tableNo]
  if(tableOrder == undefined)
  {
    response.json({})
  }
  else
  {
    response.json(tableOrder)
  }
});

// Get All Orders
router.get('/orders', (request, response)=> {
    response.json(allOrders)  
});

router.post('/order/:orderId/complete', (request, response) => {
  var orderId = request.params.orderId
  let tableOrder = allOrders[orderId]
  if(tableOrder != undefined)
  {
    tableOrder["isComplete"] = true
    response.json({"status" : "Success"})
  } else {
    response.json({"status" : "Failure"})
  }
});

router.post('/order/:orderId/pay', (request, response) => {
  var orderId = request.params.orderId
  let tableOrder = allOrders[orderId]
  if(tableOrder != undefined)
  {
    tableOrder["isPaid"] = true
    delete currentOrders[tableOrder["tableNo"]]  
    delete allMessages[tableOrder["tableNo"]]  
    response.json({"status" : "Success"})
  } else {
    response.json({"status" : "Failure"})
  }
});

router.get('/order/:orderId', (request, response)=> {
  var orderId = request.params.orderId;
  
  let tableOrder = allOrders[orderId]
  if(tableOrder == undefined)
  {
    response.json({})
  }
  else
  {
    response.json(tableOrder)
  }
});

router.get('/menuItems', (request, response) => {
    response.json(allMenu)
});


router.get('/messages', (request, response) => {
  response.json(allMessages)
});

router.get('/messages/:tableNo', (request, response) => {
  var tableNo = request.params.tableNo;
  
  let tableMessages = allMessages[tableNo]
  if(tableMessages == undefined)
  {
    response.json([])
  }
  else
  {
    response.json(tableMessages)
  }
});

router.post('/menu', (request, response) => {
  let menuItem = request.body
  allMenu.push(menuItem)
  response.json({"status" : "Success"})  
});

router.post('/menu/:id', (request, response) => {
  let id = request.params.id
  let menuItem = request.body
  allMenu = allMenu.filter(function( obj ) {
    return obj.Id !== id;
  });

  allMenu.push(menuItem)

  response.json({"status" : "Success"})  
});


router.delete('/menu/:id', (request, response) => {
  let id = request.params.id
  allMenu = allMenu.filter(function( obj ) {
    return obj.Id !== id;
  });

  response.json({"status" : "Success"})  
});

router.post('/messages/:tableNo', (request, response) => {
  var tableNo = request.params.tableNo;
  var msg = request.body
  
  let tableMessages = allMessages[tableNo]
  if(tableMessages == undefined)
  {
    allMessages[tableNo] = []
  }
  allMessages[tableNo].push(msg)

  response.json({"status" : "Success"})
});



// set the server to listen on port 3000
app.listen(port, () => console.log(`Listening on port ${port}`));