import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:share/share.dart';
import '../../../models/app_state_model.dart';
import '../../../ui/accounts/login/buttons.dart';
import '../../accounts/login/login2.dart';
import '../../../models/releated_products.dart';
import '../../../models/review_model.dart';
import '../../../blocs/product_detail_bloc.dart';
import '../../../models/product_model.dart';
import '../product_grid/product_related.dart';
import '../../checkout/cart/cart.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:html/parser.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

double expandedAppBarHeight = 350;

class ProductDetail extends StatefulWidget {
  final ProductDetailBloc productDetailBloc = ProductDetailBloc();
  Product product;

  final appStateModel = AppStateModel();
  ProductDetail({this.product});

  @override
  _ProductDetailState createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  bool _alreadySaved;
  var saved;
  ScrollController _scrollController = new ScrollController();

  List<ReviewModel> reviews;
  bool _visible = false;
  int _quantity = 1;

  var addingToCart = false;

  bool lastStatus = true;

  _scrollListener() {
    if (isShrink != lastStatus) {
      setState(() {
        lastStatus = isShrink;
      });
    }
  }

  bool get isShrink {
    return _scrollController.hasClients &&
        _scrollController.offset > (350 - kToolbarHeight);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    if (widget.product.description == null) {
      getProduct();
    }
    widget.productDetailBloc.getProductsDetails(widget.product.id);
    widget.productDetailBloc.getReviews(widget.product.id);
  }

  Future<void> addToCart() async {
    setState(() {
      addingToCart = true;
    });
    var data = new Map<String, dynamic>();
    data['product_id'] = widget.product.id.toString();
    data['quantity'] = _quantity.toString();
    var doAdd = true;
    if (widget.product.type == 'variable' &&
        widget.product.variationOptions != null) {
      for (var i = 0; i < widget.product.variationOptions.length; i++) {
        if (widget.product.variationOptions[i].selected != null) {
          data['variation[attribute_' +
              widget.product.variationOptions[i].attribute +
              ']'] = widget.product.variationOptions[i].selected;
        } else if (widget.product.variationOptions[i].selected == null &&
            widget.product.variationOptions[i].options.length != 0) {
          Fluttertoast.showToast(
              msg: widget.appStateModel.blocks.localeText.select +
                  ' ' +
                  widget.product.variationOptions[i].name);
          doAdd = false;
          break;
        } else if (widget.product.variationOptions[i].selected == null &&
            widget.product.variationOptions[i].options.length == 0) {
          setState(() {
            widget.product.stockStatus = 'outofstock';
          });
          doAdd = false;
          break;
        }
      }
      if (widget.product.variationId != null) {
        data['variation_id'] = widget.product.variationId;
      }
    }
    if (doAdd) {
      await widget.appStateModel.addToCart(data);
    }
    setState(() {
      addingToCart = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: widget.product.description != null
          ? buildBody()
          : CustomScrollView(
              slivers: <Widget>[
                _buildDBackgroundImage(),
                _buildDBackgroundCircleIndicator()
              ],
            ),
    );
  }

  List<Widget> buildSliverList() {
    List<Widget> list = new List<Widget>();
    String key;
    list.add(_buildProductImages(key));
    list.add(buildNamePrice());

    if (widget.product.availableVariations != null &&
        widget.product.availableVariations?.length != 0) {
      for (var i = 0; i < widget.product.variationOptions.length; i++) {
        if (widget.product.variationOptions[i].options.length != 0) {
          list.add(buildOptionHeader(widget.product.variationOptions[i].name));
          list.add(buildProductVariations(widget.product.variationOptions[i]));
        }
      }
    }
    //list.add(buildProductDetail());
    list.add(buildProductSortDescriptoion());
    list.add(buildProductDescriptoion());
    list.add(buildLisOfReleatedProducts());
    list.add(buildLisOfCrossSellProducts());
    list.add(buildLisOfUpSellProducts());
    list.add(buildReviews());
    return list;
  }

  Widget buildNamePrice() {
    bool onSale = false;

    if (widget.product.salePrice != null && widget.product.salePrice != 0) {
      onSale = true;
    }

    return SliverList(
        delegate: SliverChildListDelegate([
      Container(
        height: 130,
        child: Column(
          children: <Widget>[
            Expanded(
                child: Container(
                    padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    widget.product.stockStatus == 'outofstock' ? Text(
                                      widget.appStateModel.blocks.localeText.outOfStock,
                                      style: TextStyle(
                                        color: Colors.red[900],
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ) : Text(
                                      widget.appStateModel.blocks.localeText.inStock,
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        // color: Colors.orangeAccent.withOpacity(0.08),
                                      ),
                                      child: ScopedModelDescendant<AppStateModel>(
                                          builder: (context, child, model) {
                                            return IconButton(
                                              onPressed: () {
                                                if (!model.loggedIn) {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              Login()));
                                                } else {
                                                  model.updateWishList(widget.product.id);
                                                }
                                              },
                                              icon: model.wishListIds.contains(widget.product.id)
                                                  ? Icon(
                                                Icons.favorite,
                                              )
                                                  : Icon(
                                                Icons.favorite_border,
                                              ),
                                            );
                                          }),
                                    )
                                  ],
                                ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            widget.product.name,
                            maxLines: 1,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                fontFamily: 'Lexend_Deca'),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              Text(
                                (widget.product.formattedSalesPrice != null &&
                                        widget.product.formattedSalesPrice
                                            .isNotEmpty)
                                    ? _parseHtmlString(
                                        widget.product.formattedSalesPrice)
                                    : '',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    fontFamily: 'Lexend_Deca'),
                              ),
                              widget.product.onSale
                                  ? SizedBox(width: 6)
                                  : SizedBox(width: 0),
                              Text(
                                (widget.product.formattedPrice != null &&
                                        widget
                                            .product.formattedPrice.isNotEmpty)
                                    ? _parseHtmlString(
                                        widget.product.formattedPrice)
                                    : '',
                                style: TextStyle(
                                  fontFamily: 'Lexend_Deca',
                                  fontWeight: onSale
                                      ? FontWeight.w400
                                      : FontWeight.w900,
                                  fontSize: onSale ? 16 : 20,
                                  color: onSale
                                      ? Theme.of(context).hintColor
                                      : Theme.of(context).textTheme.bodyText1.color,
                                  decoration: onSale
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          /*Expanded(
                            child: Container(
                                child:  StreamBuilder<VendorDetailsModel>(
                                    stream: widget.vendorDetailsBloc.allVendorDetails,
                                    builder: (context, AsyncSnapshot<VendorDetailsModel> snapshot) {
                                      return buildStore(snapshot, context);
                                    }
                                )

                            ),
                          )*/
                        ]))),
          ],
        ),
      ),
    ]));
  }

  Widget buildLisOfReleatedProducts() {
    String title = widget.appStateModel.blocks.localeText.relatedProducts.toUpperCase();
    return StreamBuilder<ReleatedProductsModel>(
        stream: widget.productDetailBloc.relatedProducts,
        builder: (context, AsyncSnapshot<ReleatedProductsModel> snapshot) {
          if (snapshot.hasData) {
            return buildProductList(
                snapshot.data.relatedProducts, context, title);
          } else {
            return SliverToBoxAdapter();
          }
        });
  }

  Widget buildLisOfCrossSellProducts() {
    String title = widget.appStateModel.blocks.localeText.justForYou.toUpperCase();
    return StreamBuilder<ReleatedProductsModel>(
        stream: widget.productDetailBloc.relatedProducts,
        builder: (context, AsyncSnapshot<ReleatedProductsModel> snapshot) {
          if (snapshot.hasData) {
            return buildProductList(
                snapshot.data.crossProducts, context, title);
          } else {
            return SliverToBoxAdapter();
          }
        });
  }

  Widget buildLisOfUpSellProducts() {
    String title = widget.appStateModel.blocks.localeText.youMayAlsoLike.toUpperCase();
    return StreamBuilder<ReleatedProductsModel>(
        stream: widget.productDetailBloc.relatedProducts,
        builder: (context, AsyncSnapshot<ReleatedProductsModel> snapshot) {
          if (snapshot.hasData) {
            return buildProductList(
                snapshot.data.upsellProducts, context, title);
          } else {
            return SliverToBoxAdapter();
          }
        });
  }

  Widget buildReviews() {
    return StreamBuilder<List<ReviewModel>>(
        stream: widget.productDetailBloc.allReviews,
        builder: (context, AsyncSnapshot<List<ReviewModel>> snapshot) {
          if (snapshot.hasData) {
            return buildReviewsList(snapshot, context);
          } else {
            return SliverToBoxAdapter();
          }
        });
  }

  buildListTile(context, ReviewModel comment) {
    return Container(
      padding: EdgeInsets.fromLTRB(22.0, 16.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 20.0,
                backgroundImage: NetworkImage(comment.avatar),
              ),
              SizedBox(
                width: 16.0,
              ),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(comment.author,
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.w400)),
                          RatingBar(
                            initialRating: double.parse(comment.rating),
                            itemSize: 15,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            ignoreGestures: true,
                            itemCount: 5,
                            itemPadding: EdgeInsets.symmetric(horizontal: 0.0),
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (rating) {},
                          ),
                        ],
                      ),
                      Text(timeago.format(comment.date),
                          style: TextStyle(
                              fontSize: 12.0,
                              color: Theme.of(context).textTheme.caption.color))
                    ]),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          Html(data: comment.content),
        ],
      ),
    );
  }

  Widget buildReviewsList(
      AsyncSnapshot<List<ReviewModel>> snapshot, BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              buildListTile(context, snapshot.data[index]),
              Divider(
                height: 0.0,
              ),
            ]);
      }, childCount: snapshot.data.length),
    );
  }

  Container buildProductList(
      List<Product> products, BuildContext context, String title) {
    if (products.length > 0) {
      return Container(
        child: SliverList(
          delegate: SliverChildListDelegate(
            [
              products.length != null
                  ? Container(
                      height: 20,
                      padding: EdgeInsets.symmetric(horizontal: 18.0),
                      child: Text(title,
                          style: Theme.of(context).textTheme.body2.copyWith(
                              fontSize: 14, fontWeight: FontWeight.w600)))
                  : Container(),
              Container(
                  height: 250,
                  margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 14.0),
                  decoration: new BoxDecoration(
                      //color: Colors.pink,
                      ),
                  child: ListView.builder(
                      padding: EdgeInsets.all(12.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                            padding: EdgeInsets.symmetric(horizontal: 5.0),
                            width: 160,
                            child: ProductItem(
                                product: products[index],
                                onProductClick: onProductClick));
                      })),
            ],
          ),
        ),
      );
    } else {
      return Container(
        child: SliverToBoxAdapter(),
      );
    }
  }

  onProductClick(data) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ProductDetail(product: data);
    }));
  }

  _buildProductImages(String key) {
    return SliverAppBar(
      iconTheme: IconThemeData(
        color: isShrink
            ? Theme.of(context).appBarTheme.iconTheme.color
            : Colors.black,
      ),
      floating: false,
      pinned: true,
      snap: false,
      elevation: 1.0,
      actions: <Widget>[
        IconButton(
            icon: Icon(
              FlutterIcons.share_fea,
              semanticLabel: 'Share',
              color: isShrink
                  ? Theme.of(context).appBarTheme.iconTheme.color
                  : Colors.black,
            ),
            onPressed: () {
              Share.share('check out product ' + widget.product.permalink);
            }),
        Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            IconButton(
              icon: Icon(
                FlutterIcons.shopping_cart_fea,
                semanticLabel: 'Cart',
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => CartPage(),
                      fullscreenDialog: true,
                    ));
              },
            ),
            Positioned(
              // draw a red marble
              top: 2,
              right: 2.0,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => CartPage(),
                        fullscreenDialog: true,
                      ));
                },
                child: ScopedModelDescendant<AppStateModel>(
                    builder: (context, child, model) {
                  if (model.count != 0) {
                    return Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        color: Colors.redAccent,
                        child: Container(
                            padding: EdgeInsets.all(2),
                            constraints: BoxConstraints(minWidth: 20.0),
                            child: Center(
                                child: Text(
                              model.count.toString(),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  backgroundColor: Colors.redAccent),
                            ))));
                  } else
                    return Container();
                }),
              ),
            )
          ],
        ),
      ],
      expandedHeight: expandedAppBarHeight,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
            child: InkWell(
              onTap: () => null,
              child: Swiper(
                //control: new SwiperControl(),
                //viewportFraction: 0.8,
                //scale: 0.9,
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    splashColor: Theme.of(context).hintColor,
                    onTap: () => null,
                    child: Card(
                      margin: EdgeInsets.all(0.0),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(0.0)),
                      ),
                      elevation: 0.0,
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: widget.product.images[index].src,
                        imageBuilder: (context, imageProvider) => Ink.image(
                          child: InkWell(
                            splashColor: Theme.of(context).hintColor,
                            onTap: () {
                              //null;
                            },
                          ),
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                        placeholder: (context, url) =>
                            Container(color: Colors.black12),
                        errorWidget: (context, url, error) =>
                            Container(color: Colors.black12),
                      ),
                    ),
                  );
                },
                itemCount: widget.product.images.length,
                pagination: new SwiperPagination(),
                autoplay: true,
              ),
            )),
      ),
    );
  }

  buildProductVariations(VariationOption variationOption) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
      sliver: SliverGrid(
        gridDelegate: new SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 80.0,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 3,
        ),
        delegate: new SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return InkWell(
              onTap: () {
                setState(() {
                  variationOption.selected = variationOption.options[index];
                  widget.product.stockStatus = 'instock';
                });
                if (widget.product.variationOptions
                    .every((option) => option.selected != null)) {
                  var selectedOptions = new List<String>();
                  var matchedOptions = new List<String>();
                  for (var i = 0;
                      i < widget.product.variationOptions.length;
                      i++) {
                    selectedOptions
                        .add(widget.product.variationOptions[i].selected);
                  }
                  for (var i = 0;
                      i < widget.product.availableVariations.length;
                      i++) {
                    matchedOptions = new List<String>();
                    for (var j = 0;
                        j < widget.product.availableVariations[i].option.length;
                        j++) {
                      if (selectedOptions.contains(widget.product
                              .availableVariations[i].option[j].value) ||
                          widget.product.availableVariations[i].option[j].value
                              .isEmpty) {
                        matchedOptions.add(widget
                            .product.availableVariations[i].option[j].value);
                      }
                    }
                    if (matchedOptions.length == selectedOptions.length) {
                      setState(() {
                        widget.product.variationId = widget
                            .product.availableVariations[i].variationId
                            .toString();
                        widget.product.regularPrice = widget
                            .product.availableVariations[i].displayPrice
                            .toDouble();
                        widget.product.formattedPrice = widget
                            .product.availableVariations[i].formattedPrice;
                        widget.product.formattedSalesPrice = widget
                            .product.availableVariations[i].formattedSalesPrice;
                        if (widget.product.availableVariations[i]
                                .displayRegularPrice !=
                            widget.product.availableVariations[i].displayPrice)
                          widget.product.salePrice = widget.product
                              .availableVariations[i].displayRegularPrice
                              .toDouble();
                        else
                          widget.product.salePrice = null;
                      });
                      if (!widget.product.availableVariations[i].isInStock) {
                        setState(() {
                          widget.product.stockStatus = 'outofstock';
                        });
                      }
                      break;
                    }
                  }
                  if (matchedOptions.length != selectedOptions.length) {
                    setState(() {
                      widget.product.stockStatus = 'outofstock';
                    });
                  }
                }
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border:
                      variationOption.selected == variationOption.options[index]
                          ? Border.all(
                              color: Theme.of(context).accentColor, width: 2)
                          : Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(
                          1.0) //                 <--- border radius here
                      ),
                ),
                child: Text(
                  variationOption.options[index].toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: variationOption.selected ==
                            variationOption.options[index]
                        ? Theme.of(context).accentColor
                        : Theme.of(context).textTheme.title.color,
                  ),
                ),
              ),
            );
          },
          childCount: variationOption.options.length,
        ),
      ),
    );
  }

  Widget buildOptionHeader(String name) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Container(
                child: Text(
              name,
              style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Lexend_Deca',
                  fontWeight: FontWeight.w900),
            )),
          ],
        ),
      ),
    );
  }

  Widget buildBody() {
    return Stack(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 50.0),
          child: CustomScrollView(
              controller: _scrollController, slivers: buildSliverList()),
        ),
        Positioned(
          bottom: 0,
          child: _qSelector(),
        ),
        Positioned(
          bottom: 55,
          child: _animContainer(),
        )
      ],
    );
  }

  Future _openWhatsApp(String number) async {
    final url = 'https://wa.me/' + number;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget buildProductSortDescriptoion() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: Html(
          data: widget.product.shortDescription,
          defaultTextStyle: Theme.of(context).textTheme.bodyText2,
        ),
      ),
    );
  }

  Widget buildProductDescriptoion() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
        child: Html(
          data: widget.product.description,
          defaultTextStyle: Theme.of(context).textTheme.bodyText2,
        ),
      ),
    );
  }

  _buildDBackgroundImage() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      elevation: 1.0,
      backgroundColor: Colors.black12,
      actions: <Widget>[
        IconButton(
            icon: Icon(
              Icons.share,
              semanticLabel: 'Share',
              color: isShrink
                  ? Theme.of(context).appBarTheme.iconTheme.color
                  : Colors.black,
            ),
            onPressed: () {
              Share.share('check out product ' + widget.product.permalink);
            }),
        Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.shopping_basket,
                semanticLabel: 'Cart',
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => CartPage(),
                      fullscreenDialog: true,
                    ));
              },
            ),
            Positioned(
              // draw a red marble
              top: 2,
              right: 2.0,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => CartPage(),
                        fullscreenDialog: true,
                      ));
                },
                child: ScopedModelDescendant<AppStateModel>(
                    builder: (context, child, model) {
                  if (model.count != 0) {
                    return Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        color: Colors.redAccent,
                        child: Container(
                            padding: EdgeInsets.all(2),
                            constraints: BoxConstraints(minWidth: 20.0),
                            child: Center(
                                child: Text(
                              model.count.toString(),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  backgroundColor: Colors.redAccent),
                            ))));
                  } else
                    return Container();
                }),
              ),
            )
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              color: Colors.black12,
              padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
              child: Container(),
            )
          ],
        ),
      ),
      expandedHeight: expandedAppBarHeight,
    );
  }

  _buildDBackgroundCircleIndicator() {
    return SliverList(
        delegate: SliverChildListDelegate([
      Container(
        padding: EdgeInsets.all(60.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      )
    ]));
  }

  getProduct() async {
    Product product =
        await widget.productDetailBloc.getProduct(widget.product.id);
    if (product.id != null) {
      setState(() {
        widget.product = product;
      });
    }
  }

  Widget _qSelector() {
    return Container(
        width: MediaQuery.of(context).size.width,
        height: 55,
        color: Color(0xFF0043ca),
        child: Row(
          children: <Widget>[
            InkWell(
              child: Container(
                width: 70,
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'QTY',
                      style: TextStyle(
                          fontSize: 12, color: Colors.black.withOpacity(0.6)),
                    ),
                    Text(
                      '$_quantity',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  _visible = !_visible;
                });
              },
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 70,
              height: 55,
              child: AddToCartButton(
                  onPressed: () => addToCart(),
                  showProgress: addingToCart,
                  text: widget.appStateModel.blocks.localeText.addToCart),
            )
          ],
        ));
  }

  Widget _animContainer() {
    return _visible
        ? AnimatedContainer(
            duration: Duration(
              seconds: 2,
            ),
            height: 110,
            width: MediaQuery.of(context).size.width,
            curve: Curves.fastOutSlowIn,
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0.0),
                ),
                margin: EdgeInsets.all(0.0),
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.only(left: 15, top: 6, bottom: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Quantity',
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Lexend_Deca',
                                fontWeight: FontWeight.w900),
                          ),
                          IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _visible = false;
                              });
                            },
                          )
                        ],
                      ),
                      Expanded(
                        //flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              width: 50,
                              child: OutlineButton(
                                // width: 50,
                                //height: 70,
                                borderSide: _quantity == 1
                                    ? BorderSide(
                                        color: Theme.of(context).accentColor,
                                        width: 1.5)
                                    : null,
                                onPressed: () {
                                  setState(() {
                                    _quantity = 1;
                                  });
                                  _visible = false;
                                },
                                // color: Colors.white,
                                child: Center(
                                  child: Text(
                                    '1',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Lexend_Deca',
                                        //color: Colors.black,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            SizedBox(
                              width: 50,
                              child: OutlineButton(
                                // width: 50,
                                //height: 70,
                                borderSide: _quantity == 2
                                    ? BorderSide(
                                        color: Theme.of(context).accentColor,
                                        width: 1.5)
                                    : null,
                                onPressed: () {
                                  setState(() {
                                    _quantity = 2;
                                  });
                                  _visible = false;
                                },
                                //color: Colors.white,
                                child: Center(
                                  child: Text(
                                    '2',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Lexend_Deca',
                                        //color: Colors.black,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            SizedBox(
                              width: 50,
                              child: OutlineButton(
                                // width: 50,
                                //height: 70,
                                borderSide: _quantity == 3
                                    ? BorderSide(
                                        color: Theme.of(context).accentColor,
                                        width: 1.5)
                                    : null,
                                onPressed: () {
                                  setState(() {
                                    _quantity = 3;
                                  });
                                  _visible = false;
                                },
                                //color: Colors.white,
                                child: Center(
                                  child: Text(
                                    '3',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Lexend_Deca',
                                        //color: Colors.black,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            SizedBox(
                              width: 50,
                              child: OutlineButton(
                                // width: 50,
                                //height: 70,
                                borderSide: _quantity == 4
                                    ? BorderSide(
                                        color: Theme.of(context).accentColor,
                                        width: 1.5)
                                    : null,
                                onPressed: () {
                                  setState(() {
                                    _quantity = 4;
                                  });
                                  _visible = false;
                                },
                                //color: Colors.white,
                                child: Center(
                                  child: Text(
                                    '4',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Lexend_Deca',
                                        //color: Colors.black,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            SizedBox(
                              width: 50,
                              child: OutlineButton(
                                // width: 50,
                                //height: 70,
                                borderSide: _quantity == 5
                                    ? BorderSide(
                                        color: Theme.of(context).accentColor,
                                        width: 1.5)
                                    : null,
                                onPressed: () {
                                  setState(() {
                                    _quantity = 5;
                                  });
                                  _visible = false;
                                },
                                //color: Colors.white,
                                child: Center(
                                  child: Text(
                                    '5',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Lexend_Deca',
                                        //color: Colors.black,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          )
        : Container();
  }
}

String _parseHtmlString(String htmlString) {
  var document = parse(htmlString);

  String parsedString = parse(document.body.text).documentElement.text;

  return parsedString;
}
