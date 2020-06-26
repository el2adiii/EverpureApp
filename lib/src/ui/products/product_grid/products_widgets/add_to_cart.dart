import './../../../../models/app_state_model.dart';
import './../../../../models/product_model.dart';
import 'package:flutter/material.dart';

class AddToCart extends StatefulWidget {

  AddToCart({
    Key key,
    @required this.product,
    @required this.model,
  }) : super(key: key);

  final Product product;
  final AppStateModel model;
  
  @override
  _AddToCartState createState() => _AddToCartState();
}

class _AddToCartState extends State<AddToCart> {
  
  var isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    if(getQty() != 0 || isLoading)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).textTheme.bodyText1.color.withOpacity(0.6)),
            tooltip: 'Increase quantity by 1',
            onPressed: () {
              increaseQty();
            },
          ),
          isLoading ? SizedBox(
            child: Theme(
              data: Theme.of(context).copyWith(
                accentColor: Theme.of(context).textTheme.bodyText1.color
              ),
                child: CircularProgressIndicator(strokeWidth: 1)
            ),
            height: 20.0,
            width: 20.0,
          ) :  SizedBox(
            width: 20.0,
            child: Text(getQty().toString(), textAlign: TextAlign.center,),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).textTheme.bodyText1.color.withOpacity(0.6)),
            tooltip: 'Decrease quantity by 1',
            onPressed: () {
              decreaseQty();
            },
          ),
        ],
      );
    else return RaisedButton(
      elevation: 0,
      color: Colors.deepOrange,
      colorBrightness: Brightness.dark,
      shape: StadiumBorder(),
      child: const Padding(
        padding: EdgeInsets.all(0.0),
        child: Text("ADD", ),
      ),
      onPressed: () {
        addToCart();
      },
    );
  }

  addToCart() async {
    var data = new Map<String, dynamic>();
    data['product_id'] = widget.product.id.toString();
    data['quantity'] = '1';
    setState(() {
      isLoading = true;
    });
    await widget.model.addToCart(data);
    setState(() {
      isLoading = false;
    });
  }

  decreaseQty() async {
    if (widget.model.shoppingCart?.cartContents != null) {
      if (widget.model.shoppingCart.cartContents
          .any((cartContent) => cartContent.productId == widget.product.id)) {
        final cartContent = widget.model.shoppingCart.cartContents
            .singleWhere((cartContent) => cartContent.productId == widget.product.id);
        setState(() {
          isLoading = true;
        });
        await widget.model.decreaseQty(cartContent.key, cartContent.quantity);
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  increaseQty() async {
    if (widget.model.shoppingCart?.cartContents != null) {
      if (widget.model.shoppingCart.cartContents
          .any((cartContent) => cartContent.productId == widget.product.id)) {
        final cartContent = widget.model.shoppingCart.cartContents
            .singleWhere((cartContent) => cartContent.productId == widget.product.id);
        setState(() {
          isLoading = true;
        });
        bool status = await widget.model.increaseQty(cartContent.key, cartContent.quantity);
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  getQty() {
    if(widget.model.shoppingCart.cartContents.any((element) => element.productId == widget.product.id)) {
      return widget.model.shoppingCart.cartContents.firstWhere((element) => element.productId == widget.product.id).quantity;
    } else return 0;
  }
}
