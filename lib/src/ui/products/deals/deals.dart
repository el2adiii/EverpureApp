import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../models/app_state_model.dart';
import '../../../models/delas_state_model.dart';
import '../../../ui/products/product_grid/product_item.dart';
import '../../../models/product_model.dart';
import 'package:flutter/rendering.dart';

class Deals extends StatefulWidget {
  AppStateModel appStateModel = AppStateModel();
  DealsStateModel model = DealsStateModel();
  Deals({Key key})
      : super(key: key);

  @override
  _DealsState createState() => _DealsState();
}

class _DealsState extends State<Deals>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    super.initState();
    widget.model.fetchDealProducts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        widget.model.loadMoreDelasProduct();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async  {
        await widget.model.refresh();
        return;
      },
      child: ScopedModel<DealsStateModel>(
          model: widget.model,
          child: ScopedModelDescendant<DealsStateModel>(
              builder: (context, child, model) {
                if (model.dealsProducts != null) {
                  if(model.dealsProducts.length != 0) {
                    return CustomScrollView(
                      controller: _scrollController,
                      slivers: buildLisOfBlocks(model.dealsProducts, model.hasMoreItems),
                    );
                  } else {
                    return Stack(
                      children: <Widget>[
                        ListView(
                          children: <Widget>[
                            Container(),
                          ],
                        ),
                        Center(child: Text(widget.appStateModel.blocks.localeText.noProducts),)
                      ],
                    );
                  }
                } return Center(child: CircularProgressIndicator());
              }),
      )
    );
  }

  List<Widget> buildLisOfBlocks(List<Product> products, bool hasMoreItems) {
    List<Widget> list = new List<Widget>();
    if (products.length != 0) {
      list.add(ProductGrid(products: products));
      list.add(SliverPadding(
          padding: EdgeInsets.all(0.0),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            Container(
                height: 60,
                child: hasMoreItems ? Center(child: CircularProgressIndicator()) : Center(child: Text(widget.appStateModel.blocks.localeText.noMoreProducts)))
          ]))));
    }
    return list;
  }
}
